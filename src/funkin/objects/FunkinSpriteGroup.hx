package funkin.objects;

import flixel.math.FlxAngle;

/**
 * A variation of FlxSpriteGroup simply meant to make other transformations smarter.
 */
class FunkinSpriteGroup<T:FlxSprite = FlxSprite> extends FlxTypedSpriteGroup<T> {
	var _applyAngleSin:Float;
	var _applyAngleCos:Float;

	var _lastScale:FlxPoint;
	var _lastScroll:FlxPoint;
	var _cancelDraw:Bool = false;

	// reduce `setXCallback` and `setYCallback` by internal `FlxPoint.scale`
	extern inline function scalePoint(point:FlxPoint, by:FlxPoint)
		point.set(point.x * by.x, point.y * by.y);
	extern inline function divPoint(point:FlxPoint, by:FlxPoint)
		point.set(point.x / by.x, point.y / by.y);

	override function initVars() @:privateAccess {
		super.initVars();
		_lastScale = FlxPoint.get(scale.x, scale.y);
		_lastScroll = FlxPoint.get(scrollFactor.x, scrollFactor.y);
		
		var callbackScale:FlxCallbackPoint = cast scale;
		callbackScale._setXCallback = callbackScale._setYCallback = callbackScale._setXYCallback = smartScaleCallback;
		var callbackScroll:FlxCallbackPoint = cast scale;
		callbackScroll._setXCallback = callbackScroll._setYCallback = callbackScroll._setXYCallback = smartScrollCallback;
	}

	override function preAdd(sprite:T) {
		final spr:FlxSprite = cast sprite;
		updateTrig();
		spr.setPosition(
			(spr.x * scale.x) * _cosAngle - (spr.y * scale.y) * _sinAngle + x,
			(spr.x * scale.x) * _sinAngle + (spr.y * scale.y) * _cosAngle + y
		);
		scalePoint(spr.scale, scale);
		scalePoint(spr.scrollFactor, scrollFactor);
		spr.angle += angle;
		spr.alpha = directAlpha ? alpha : spr.alpha * alpha;

		if (clipRect != null)
			clipRectTransform(sprite, clipRect);
	}
	override function remove(sprite:T, splice:Bool = false):T {
		updateTrig();

		final spr:FlxSprite = cast sprite;
		final _sinAngle:Float = -_sinAngle; // sin(-theta) = -sin(theta), cos(-theta) = cos(theta)
		spr.setPosition(
			((spr.x - this.x) * _cosAngle - (spr.y - this.y) * _sinAngle) / scale.x,
			((spr.x - this.x) * _sinAngle + (spr.y - this.y) * _cosAngle) / scale.y
		);
		divPoint(spr.scale, scale);
		divPoint(spr.scrollFactor, scrollFactor);

		if (!directAlpha)
			spr.alpha /= alpha;

		return group.remove(sprite, splice);
	}

	// extern bc its just internal
	// also this exists bc Haxe.
	extern inline function transform<V>(func:FlxSprite->V->Void, val:V) {
		if (!_skipTransformChildren && group != null) {
			for (spr in _sprites) {
				if (spr != null)
					func(spr, val);
			}
		}
	}

	inline function applyScale(to:FlxSprite, point:FlxPoint) {
		var result = to._point.set(to.x - this.x, to.y - this.y);

		// undo the rotation so if rotation were to change, scale would be right.
		result.rotateWithTrig(-_sinAngle, _cosAngle); // sin(-theta) = -sin(theta), cos(-theta) = cos(theta)
		result.scale(point.x, point.y);
		result.rotateWithTrig(_sinAngle, _cosAngle);

		to.setPosition(result.x + this.x, result.y + this.y);
		scalePoint(to.scale, point);
	}
	function smartScaleCallback(point:FlxPoint) {
		updateTrig();
		
		_point.set(point.x / _lastScale.x, point.y / _lastScale.y);
		_lastScale.set(point.x, point.x);
		transform(applyScale, _point);
	}

	inline function applyScroll(to:FlxSprite, point:FlxPoint)
		scalePoint(to.scrollFactor, point);
	function smartScrollCallback(point:FlxPoint) {
		var basePoint:FlxBasePoint = cast point;
		if (basePoint.x == 0)
			@:bypassAccessor basePoint.x = 0.0001;
		if (basePoint.y == 0)
			@:bypassAccessor basePoint.y = 0.0001;
		_cancelDraw = point.x == 0.0001 || point.y == 0.0001 || alpha == 0.0001;

		_point.set(point.x / _lastScroll.x, point.y / _lastScroll.y);
		_lastScroll.set(point.x, point.x);
		transform(applyScroll, _point);
	}

	inline function applyAngle(to:FlxSprite, val:Float) {
		to.setPosition(
			((to.x - this.x) * _applyAngleCos - (to.y - this.y) * _applyAngleSin) + to.x,
			((to.x - this.x) * _applyAngleSin + (to.y - this.y) * _applyAngleCos) + to.y
		);
		to.angle += val;
	}
	override function set_angle(to:Float) {
		if (exists && angle != to) {
			_angleChanged = true;
			final rads = FlxAngle.asRadians(to - angle);
			_applyAngleSin = Math.sin(rads);
			_applyAngleCos = Math.cos(rads);
			transform(applyAngle, to - angle);
		}
		return angle = to;
	}

	inline function unsafeApplyAlpha(to:FlxSprite, val:Float)
		to.alpha *= val; // just multiply since we allow preservation with alpha (the old ones were smarter but we don't need that, hence, unsafe.)
	inline function directApplyAlpha(to:FlxSprite, val:Float) // Haxe.
		to.alpha = val;
	override function set_alpha(to:Float) {
		_cancelDraw = scale.x == 0.0001 || scale.y == 0.0001 || to <= 0.0001;
		to = FlxMath.bound(to, 0.0001, 1); // cap so it can be somewhat preserved

		if (exists && alpha != to) {
			if (!directAlpha)
				transform(unsafeApplyAlpha, to / alpha);
			else
				transform(directApplyAlpha, to);
		}
		return alpha = to;
	}

	override function get_camera()
		return group.get_camera();
	override function set_camera(to:FlxCamera)
		return group.set_camera(to);

	override function get_cameras()
		return group.get_cameras();
	override function set_cameras(to:Array<FlxCamera>)
		return group.set_cameras(to);

	override function draw() {
		if (_cancelDraw)
			return;

		group.draw();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
}