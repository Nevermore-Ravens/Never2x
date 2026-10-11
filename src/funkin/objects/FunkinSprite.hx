package funkin.objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;

typedef FunkinAnimData = {
	var name:String;
	var id:String;
	
	var ?offset:Array<Float>;
	var ?framerate:Float;
	var ?looped:Bool;
	var ?indices:Array<Int>;
	var ?useFrameLabel:Bool;
}

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

	public function makeAnimFromData(data:FunkinAnimData) {
		var hasSymbol:Bool = library != null && library.getSymbol(data.id) != null;
		var hasIndices:Bool = data.indices != null && data.indices.length > 0;
		var useLabel:Bool = data.useFrameLabel == true;
		var fps:Float = data.framerate ?? 24;
		var loop:Bool = data.looped == true;

		switch ([hasSymbol, useLabel, hasIndices]) {
			case [false,	false,	false]:		anim.addByPrefix(data.name, data.id, fps, loop);
			case [false,	false,	true]:		anim.addByIndices(data.name, data.id, data.indices, "", fps, loop);
			case [true,		false,	false]:		anim.addBySymbol(data.name, data.id, fps, loop);
			case [true,		false,	true]:		anim.addBySymbolIndices(data.name, data.id, data.indices, fps, loop);
			case [_,		true,	false]:		anim.addByFrameLabel(data.name, data.id, fps, loop);
			case [_,		true,	true]:		anim.addByFrameLabelIndices(data.name, data.id, data.indices, fps, loop);
		}
		setOffset(data.name, data.offset ?? [0, 0]);
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

	override function prepareDrawMatrix(matrix:FlxMatrix, camera:FlxCamera) {
		final doStageMatrix:Bool = (isAnimate && applyStageMatrix);

		if (doStageMatrix) {
			if (postStageMatrixApply) {
				matrix.translate(timeline._bounds.x, timeline._bounds.y);
			} else {
				matrix.concat(library.matrix);
				matrix.translate(timeline._bounds.x * library.matrix.a, timeline._bounds.y * library.matrix.d);
			}
		}

		matrix.translate(-origin.x, -origin.y);
		matrix.translate(-frameOffset.x, -frameOffset.y);
		matrix.scale(scale.x, scale.y);

		if (angle != 0) {
			updateTrig();
			matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		if (skew.x != 0 || skew.y != 0) {
			updateSkew();
			@:privateAccess matrix.concat(animate.FlxAnimate._skewMatrix);
		}

		if (doStageMatrix && postStageMatrixApply)
			matrix.concat(library.matrix);

		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
			preparePixelPerfectMatrix(matrix);
	}
}