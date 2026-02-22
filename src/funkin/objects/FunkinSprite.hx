package funkin.objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;

class FunkinSprite extends animate.FlxAnimate {
	public var offsetMap:Map<String, Array<Float>> = [];
	public var zoomFactor(default, null):FlxPoint;
	public var frameOffset(default, null):FlxPoint;

	public function new(?x:Float, ?y:Float, ?graphic:FlxGraphicAsset) {
		super(x, y, graphic);
		moves = false;
		active = false;
		antialiasing = FlxSprite.defaultAntialiasing;
	}

	override function initVars() {
		super.initVars();

		zoomFactor = FlxPoint.get(1, 1);
		frameOffset = FlxPoint.get();
	}

	override function destroy() {
		super.destroy();

		zoomFactor = FlxDestroyUtil.put(zoomFactor);
		frameOffset = FlxDestroyUtil.put(frameOffset);
	}

	override function clone():FunkinSprite {
		final sprite = new FunkinSprite(x, y);
		sprite.loadGraphicFromSprite(this);
		sprite.scale.copyFrom(this.scale);
		sprite.scrollFactor.copyFrom(this.scrollFactor);
		sprite.zoomFactor.copyFrom(this.zoomFactor);
		return sprite;
	}

	// knew this was gonna get to me eventually lol
	override function loadGraphicFromSprite(sprite:FlxSprite):FunkinSprite {
		super.loadGraphicFromSprite(sprite);
		return this;
	}

	override function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):FunkinSprite {
		super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
		return this;
	}

	override function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):FunkinSprite	{
		super.makeGraphic(width, height, color, unique, key);
		return this;
	}

	override function set_antialiasing(v:Bool):Bool {
		if (!Settings.data.antialiasing) return antialiasing = false;
		return antialiasing = v;
	}

	public function scaleToGame():FunkinSprite {
		final v = 1.0 / Math.min(frameWidth / FlxG.width, frameHeight / FlxG.height);
		scale.set(v, v);
		updateHitbox();

		return this;
	}

	public function setOffset(name:String, offsets:Array<Float>) offsetMap.set(name, offsets);

	public function playAnim(name:String, ?forced:Bool = true, ?suffix:String = "") {
		var fullName = name + suffix;
		if (!animation.exists(fullName)) fullName = name;
		if (!animation.exists(fullName)) return;

		final offsetsForAnim:Array<Float> = offsetMap[fullName] ?? [0, 0];

		animation.play(fullName, forced);
		active = animation.curAnim != null ? animation.curAnim.frames.length > 1 : false;
		//this shit messes with the real position of the sprite, like it happened with the reflections
		//it messes with getGraphicMidpoint(); too
		frameOffset.set(offsetsForAnim[0], offsetsForAnim[1]);
	}

	public function isSimpleZoomFactor():Bool return FlxMath.equal(1, zoomFactor.x) && FlxMath.equal(1, zoomFactor.y);

	private inline function prepareZoomFactor(?rect:FlxRect, camera:FlxCamera):FlxRect {
		return (rect ?? FlxRect.get()).set(
			camera.width * 0.5 + camera.scroll.x * scrollFactor.x,
			camera.height * 0.5 + camera.scroll.y * scrollFactor.y,
			(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor.x)),
			(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor.y))
		);
	}

	// basically the beginning of drawComplex
	function prepareMatrix(matrix:FlxMatrix, camera:FlxCamera) {
		matrix.translate(-origin.x, -origin.y);
		matrix.translate(-frameOffset.x, -frameOffset.y);
		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			@:privateAccess matrix.concat(animate.FlxAnimate._skewMatrix);
		}

		getScreenPosition(_point, camera).subtractPoint(offset).add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		if (!isSimpleZoomFactor()) {
			prepareZoomFactor(_rect, camera);
			matrix.setTo(
				matrix.a * _rect.width, matrix.b * _rect.height,
				matrix.c * _rect.width, matrix.d * _rect.height,
				(matrix.tx - _rect.x) * _rect.width + _rect.x,
				(matrix.ty - _rect.y) * _rect.height + _rect.y,
			);
		}

		if (isPixelPerfectRender(camera)) {
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
	}

	override function drawAnimate(camera:FlxCamera):Void {
		final bounds = @:privateAccess timeline._bounds;
		_matrix.setTo(1, 0, 0, 1, -bounds.x, -bounds.y);

		if (checkFlipX()) {
			_matrix.scale(-1, 1);
			_matrix.translate(frame.sourceSize.x, 0);
		}

		if (checkFlipY()) {
			_matrix.scale(1, -1);
			_matrix.translate(0, frame.sourceSize.y);
		}

		if (applyStageMatrix) {
			_matrix.concat(library.matrix);
			_matrix.translate(-library.matrix.tx, -library.matrix.ty);
		}

		prepareMatrix(_matrix, camera);

		if (renderStage)
			drawStage(camera);

		timeline.currentFrame = animation.frameIndex;
		timeline.draw(camera, _matrix, colorTransform, blend, antialiasing, shader);
	}

	override function drawComplex(camera:FlxCamera) {
		_frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX(), checkFlipY());
		prepareMatrix(_matrix, camera);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader, wrapMode);
	}
}