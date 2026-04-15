package funkin.objects;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Graphics;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;

import openfl.utils.BitmapDataUtil;

// Captures objects behind in the camera it's in.

@:access(openfl.display.Graphics)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.FlxCamera)
@:access(flixel.FlxGame)
@:keep
class SpriteFrameBuffer extends FlxBasic {
	public var bitmap:BitmapData;
	public var autoSize:Bool;
	public var destroyBitmap:Bool = true;

	public var alpha:Float = 1.0;
	public var flipX:Bool = false;
	public var flipY:Bool = false;

	public var graphic(default, null):FlxGraphic;
	public var frames(default, null):FlxFramesCollection;
	public var frame(default, null):FlxFrame;
	public var frameWidth(get, never):Int; function get_frameWidth() return Math.ceil(frame.sourceSize.x);
	public var frameHeight(get, never):Int; function get_frameHeight() return Math.ceil(frame.sourceSize.y);

	public var clearBehind:Bool = false;
	public var preserve:Bool = true;

	public var frameRate(default, set):Float;
	public var frameDuration:Float;
	public var dirty:Bool = true;

	function set_frameRate(value:Float):Float {
		frameDuration = value < 0.0 ? 0.0 : 1.0 / value;
		return value;
	}

	var _frameTimer:Float = 0;
	var _helperGraphic:FlxGraphic;
	var _helperFrame:FlxFrame;

	public function new(frameRate = -1.0, ?bitmap:BitmapData, autoSize = true) {
		super();

		this.frameRate = frameRate;
		this.autoSize = autoSize;
		this.bitmap = bitmap ?? (autoSize ? BitmapDataUtil.create(0, 0) : null);

		(graphic = new FlxGraphic('SpriteFrameBuffer$ID', this.bitmap)).destroyOnNoUse = false;
		frame = (frames = graphic.imageFrame = FlxImageFrame.fromGraphic(graphic)).frames[0];
		FlxG.bitmap.addGraphic(graphic);

		(_helperGraphic = new FlxGraphic('SpriteFrameBuffer${ID}Helper', null)).destroyOnNoUse = false;
		_helperFrame = (_helperGraphic.imageFrame = FlxImageFrame.fromGraphic(_helperGraphic)).frames[0];
		FlxG.bitmap.addGraphic(_helperGraphic);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if ((_frameTimer += elapsed) > frameDuration) {
			_frameTimer = Math.min(_frameTimer - frameDuration, frameDuration);
			dirty = true;
		}
	}

	override function draw() {
		if (dirty) {
			capture(camera);
			dirty = false;
		}
	}

	inline function updateFrame(frame:FlxFrame, graphic:FlxGraphic, bitmap:BitmapData) if (bitmap != null) {
		if (graphic.bitmap != bitmap) graphic.bitmap = bitmap;
		else @:privateAccess {
			graphic.width = bitmap.width;
			graphic.height = bitmap.height;
		}
		frame.sourceSize.set(bitmap.width, bitmap.height);
		frame.frame.set(0, 0, bitmap.width, bitmap.height);
		frame.frame = frame.frame;
	}

	private function capture(camera:FlxCamera) @:privateAccess {
		camera.render();

		final matrix = camera._helperMatrix ?? (camera._helperMatrix = new FlxMatrix());
		matrix.identity();

		final rect = Rectangle.__pool.get();
		camera.flashSprite.__getFilterBounds(rect, matrix);

		final pixelRatio = camera.flashSprite.__cacheBitmapRenderer?.__pixelRatio ?? 1;
		final filterWidth = rect.width > 0 ? Math.ceil(rect.width * pixelRatio) : 0,
			filterHeight = rect.height > 0 ? Math.ceil(rect.height * pixelRatio) : 0;

		Rectangle.__pool.release(rect);

		var cacheBitmapData2 = camera.flashSprite.__cacheBitmapData2 = BitmapDataUtil.prepareCacheBitmapData(camera.flashSprite.__cacheBitmapData2, filterWidth, filterHeight);

		BitmapDataUtil.clear(cacheBitmapData2);
		BitmapDataUtil.draw(cacheBitmapData2, camera.canvas, camera.canvas.__transform, false, true);

		camera.clearDrawStack();
		camera.canvas.graphics.clear();

		if (bitmap != null) {
			if (autoSize) {
				BitmapDataUtil.resize(bitmap, Math.ceil(camera.width * FlxG.scaleMode.scale.x),
					Math.ceil(camera.height * FlxG.scaleMode.scale.y));
			}
			updateFrame(frame, graphic, bitmap);

			if (!preserve) BitmapDataUtil.clear(bitmap);

			matrix.identity();
			matrix.scale(bitmap.width / filterWidth, bitmap.height / filterHeight);

			if (flipX) {
				matrix.scale(-1, 1);
				matrix.translate(bitmap.width, 0);
			}
			if (flipY) {
				matrix.scale(1, -1);
				matrix.translate(0, bitmap.height);
			}

			BitmapDataUtil.copyFrom(bitmap, cacheBitmapData2, alpha, matrix, true);
		}

		if (!clearBehind) {
			var cacheBitmapData = camera.flashSprite.__cacheBitmapData = BitmapDataUtil.prepareCacheBitmapData(camera.flashSprite.__cacheBitmapData, filterWidth, filterHeight);
			
			BitmapDataUtil.clear(cacheBitmapData);
			BitmapDataUtil.copyFrom(cacheBitmapData, cacheBitmapData2);

			updateFrame(_helperFrame, _helperGraphic, cacheBitmapData);

			matrix.copyFrom(camera.canvas.__transform);
			matrix.invert();
			camera.drawPixels(_helperFrame, cacheBitmapData, matrix);
		}
	}

	override function destroy() {
		super.destroy();

		frame = FlxDestroyUtil.destroy(frame);
		frames = null;
		if (destroyBitmap) bitmap = FlxDestroyUtil.dispose(bitmap);
		if (graphic != null) {
			Reflect.setField(graphic, "bitmap", null);
			graphic = FlxDestroyUtil.destroy(graphic);
		}

		if (_helperGraphic != null) {
			Reflect.setField(_helperGraphic, "bitmap", null);
			_helperGraphic = FlxDestroyUtil.destroy(_helperGraphic);
		}
		_helperFrame = null;
	}
}