package funkin.objects;

import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMatrix;
import flixel.math.FlxAngle;
import openfl.display.BitmapData;

class SkewedText extends FlxText {
	public var skew:FlxPoint;

	override function initVars():Void {
		super.initVars();
		skew = FlxPoint.get();
	}
	override function destroy() {
		super.destroy();
		skew = FlxDestroyUtil.put(skew);
	}

	// why not
	function prepareDrawMatrix(matrix:FlxMatrix, camera:FlxCamera):Void {
		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0) {
			updateTrig();

			if (angle != 0)
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (skew.x != 0 || skew.y != 0) {
			@:privateAccess var skewMatrix = animate.FlxAnimate._skewMatrix;
			skewMatrix.setTo(1, Math.tan(skew.y * FlxAngle.TO_RAD), Math.tan(skew.x * FlxAngle.TO_RAD), 1, 0, 0);
			matrix.concat(skewMatrix);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera)) {
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
	}
	override function drawComplex(camera:FlxCamera):Void {
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		prepareDrawMatrix(_matrix, camera);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader, wrapMode);
	}

	// these 3 functions are just to make borderSize look a lil nicer

	// heavy copy-paste but applies extra padding based on borderSize
	override function regenGraphic():Void {
		if (textField == null || !_regen)
			return;

		var oldWidth:Int = 0;
		var oldHeight:Int = FlxText.VERTICAL_GUTTER;

		if (graphic != null) {
			oldWidth = graphic.width;
			oldHeight = graphic.height;
		}

		var newWidth:Int = Math.ceil(textField.width + borderSize * _borderSizeOffsetX);
		var textfieldHeight = _autoHeight ? textField.textHeight : textField.height;
		var vertGutter = _autoHeight ? FlxText.VERTICAL_GUTTER : 0;
		// Account for gutter
		var newHeight:Int = Math.ceil(textfieldHeight + borderSize * _borderSizeOffsetY) + vertGutter;

		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight == 0)
			newHeight = oldHeight;

		if (oldWidth != newWidth || oldHeight != newHeight) {
			// Need to generate a new buffer to store the text graphic
			var key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, false, key);

			if (_hasBorderAlpha)
				_borderPixels = graphic.bitmap.clone();

			if (_autoHeight)
				textField.height = newHeight;

			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		} else {
			// Else just clear the old buffer before redrawing the text
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha) {
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null) {
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();

			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}

	var _borderSizeOffsetX:Float = 0;
	var _borderSizeOffsetY:Float = 0;
	var _borderOffsetX:Float = 0;
	var _borderOffsetY:Float = 0;
	override function drawTextFieldTo(graphic:BitmapData):Void {
		// basically just some extra offset since borderSize now pads
		_matrix.translate(borderSize * _borderOffsetX, borderSize * _borderOffsetY);
		super.drawTextFieldTo(graphic);
		_matrix.translate(-borderSize * _borderOffsetX, -borderSize * _borderOffsetY);
	}

	override function set_borderStyle(style:FlxTextBorderStyle):FlxTextBorderStyle {
		if (style != borderStyle) {
			_regen = true;

			switch (style) {
				case NONE:
					_borderOffsetX = 0;
					_borderOffsetY = 0;
					_borderSizeOffsetX = 0;
					_borderSizeOffsetY = 0;
				case OUTLINE | OUTLINE_FAST:
					_borderOffsetX = 1;
					_borderOffsetY = 1;
					_borderSizeOffsetX = 2;
					_borderSizeOffsetY = 2;
				case SHADOW:
					_borderOffsetX = -Math.min(shadowOffset.x, 0);
					_borderOffsetY = -Math.min(shadowOffset.y, 0);
					_borderSizeOffsetX = Math.abs(shadowOffset.x);
					_borderSizeOffsetY = Math.abs(shadowOffset.y);
			}
		}

		return borderStyle = style;
	}
}