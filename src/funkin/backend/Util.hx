package funkin.backend;

import openfl.geom.ColorTransform;
import haxe.ds.Vector;
import funkin.backend.Addons;

class Util {
	/**
		Resets the music to the menu music, addon, and travel to a state.
	**/
	public static function toMenu(target:FlxState) {
		if (Conductor.vocals != null)
			Conductor.vocals.destroy();

		Conductor.reset();
		Conductor.inst = FlxG.sound.load(Assets.audio('music/freakyMenu'), true);
		Conductor.clock.timingMap.reset([{tempo: 102}]);
		Conductor.metronome = false;
		Conductor.play();
		Addons.current = null;
		FunkinState.switchState(target);
	}

	inline public static function quantize(f:Float, snap:Float):Float
		return Math.fround(f * snap) / snap;

	public static function ilerp(from:Float, to:Float, weight:Float):Float
		return from + FlxMath.bound(weight * 60 * FlxG.elapsed, 0, 1) * (to - from);

	public static function expDecay(a:Float, b:Float, decay:Float)
		return b + (a - b) * Math.exp(-decay * FlxG.elapsed);

	public static function isLetter(c:String)
	{ // thanks kade
		var ascii:Int = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	inline public static function listFromString(string:String):Array<String>
		return string.trim().split('\n');

	// FlxStringUtil.formatBytes() but it just adds a space between the size and the unit lol
	public static function formatBytes(bytes:Float, ?precision:Int = 2):String {
		static final units:Array<String> = ["Bytes", "KB", "MB", "GB", "TB", "PB"];
		var curUnit:Int = 0;
		while (bytes >= 1024 && curUnit < units.length - 1)
		{
			bytes /= 1024;
			curUnit++;
		}

		return '${FlxMath.roundDecimal(bytes, precision)} ${units[curUnit]}';
	}

	public static function moneyString(number:Float) {
		final strNum = Std.string(number);
		final decIdx = strNum.indexOf(".");
		var targetLen = (decIdx > -1 ? decIdx : strNum.length);
		var curLen = (targetLen % 3 == 0) ? 3 : targetLen % 3;
		var result = strNum.substr(0, curLen);
		while (curLen < targetLen) {
			result += "," + strNum.substr(curLen, 3);
			curLen += 3;
		}
		return (decIdx > -1 ? result + strNum.substring(decIdx, strNum.length) : result);
	}

	public static inline function format(string:String):String
		return string.toLowerCase().replace(' ', '-');

	inline public static function capitalize(text:String):String
		return '${text.charAt(0).toUpperCase()}${text.substr(1).toLowerCase()}';

	public static function mean(values:Array<Float>):Float {
		final amount:Int = values.length;
		var result:Float = 0.0;

		var value:Float = 0;
		for (i in 0...amount)
		{
			value = values[i];
			if (value == 0)
				continue;
			result += value;
		}

		return result / amount;
	}

	public static function clipByCoords(obj:FlxSprite, ?left:Float, ?right:Float, ?top:Float, ?bottom:Float) {
		if (obj is FlxText)
			@:privateAccess cast(obj, FlxText).regenGraphic();

		var leftClip:Float = 0;
		var widClip:Float = obj.graphic.width;
		if (left != null || right != null) {
			final leftCoord:Float = obj.x - (obj.origin.x * obj.scale.x) + obj.origin.x;
			final rightCoord:Float = leftCoord + obj.graphic.width * obj.scale.x;

			if (left != null) {
				final lClipResult:Float = Math.max(left - leftCoord, 0) / obj.scale.x;
				leftClip = lClipResult;
				widClip -= lClipResult;
				obj.offset.x = -lClipResult * obj.scale.x;
			}

			if (right != null)
				widClip -= Math.max(rightCoord - right, 0) / obj.scale.x;
		}

		var topClip:Float = 0;
		var heiClip:Float = obj.graphic.height;
		if (top != null || bottom != null) {
			final topCoord:Float = obj.y - (obj.origin.y * obj.scale.y) + obj.origin.y;
			final bottomCoord:Float = topCoord + obj.graphic.height * obj.scale.y;

			if (top != null) {
				final tClipResult:Float = Math.max(top - topCoord, 0) / obj.scale.y;
				topClip = tClipResult;
				heiClip -= tClipResult;
				obj.offset.y = -tClipResult * obj.scale.y;
			}

			if (bottom != null)
				heiClip -= Math.max(bottomCoord - bottom, 0) / obj.scale.y;
		}

		obj.clipGraphic(leftClip, topClip, widClip, heiClip);
		obj.visible = obj.frameWidth > 0 && obj.frameHeight > 0;
	}

	// FlxColor.interpolate can't get to the finish well
	public static function lerpColorTransform(transform:ColorTransform, color:FlxColor, ratio:Float, ?alpha:Float) {
		transform.redMultiplier = FlxMath.lerp(transform.redMultiplier, color.redFloat, ratio);
		transform.greenMultiplier = FlxMath.lerp(transform.greenMultiplier, color.greenFloat, ratio);
		transform.blueMultiplier = FlxMath.lerp(transform.blueMultiplier, color.blueFloat, ratio);

		if (alpha != null)
			transform.alphaMultiplier = FlxMath.lerp(transform.alphaMultiplier, alpha, ratio);
	}

	public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color) ?? FlxColor.fromString('#$color');
		return colorNum ?? FlxColor.WHITE;
	}

	public static function truncateFloat(number:Float, precision:Float = 2):Float {
		number *= (precision = Math.pow(10, precision));
		return Math.floor(number) / precision;
	}

	public inline static function quantizeFloat(number:Float, quantize:Float = 100):Float {
		return Math.floor(number * quantize) / quantize;
	}

	public inline static function openURL(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function openFolder(folder:String, ?absolute:Bool = false) {
		#if sys
		if (!absolute)
			folder = '${Sys.getCwd()}$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/'))
			folder.substr(0, folder.length - 1);

		Sys.command(#if linux '/usr/bin/xdg-open' #else 'explorer.exe' #end, [folder]);
		#else
		FlxG.error("Platform is not supported for Util.openFolder");
		#end
	}

	public static function cancelAllTimers() {
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null) tmr.cancel());
	}

	public static function cancelAllTweens() {
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null) twn.cancel());
	}

	public static function easeFromString(str:String) {
		str = str.toLowerCase();

		// work smarter not harder
		if (str.endsWith("inout"))
			str = str.substring(0, str.length - 5) + "InOut";
		else if (str.endsWith("out"))
			str = str.substring(0, str.length - 3) + "Out";
		else if (str.endsWith("in"))
			str = str.substring(0, str.length - 2) + "In";

		if (str.contains("step")) // sorta hardcoded but luckily step's the only multi word ease
			str = str.replace("step", "Step");

		return Reflect.field(flixel.tweens.FlxEase, str) ?? FlxEase.linear;
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		final file:String = FlxG.stage.application.meta.get('file');

		return '${company}/${flixel.util.FlxSave.validate(file)}';
	}

	public inline static function getOperatingSystem():String {
		#if windows
		return 'Windows';
		#elseif linux
		return 'Linux';
		#elseif (mac || macos)
		return 'macOS';
		#else
		return 'Unknown';
		#end
	}

	public inline static function getTarget():String {
		#if cpp
		return 'C++';
		#elseif hl
		return 'Hashlink';
		#else
		return 'Unknown';
		#end
	}
}
