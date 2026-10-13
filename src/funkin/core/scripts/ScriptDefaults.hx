package funkin.core.scripts;

import nevermore.modchart.ModchartManager;
import flixel.util.FlxColor;
import flixel.FlxG;

class ScriptDefaults {
	// this one can actually be useful outside of scripts so....
	public static function range(from:Float, to:Float, interval:Float = 1):Iterator<Float> {
		var cur = from;
		return {
			next: function() {
				cur += interval;
				return cur - interval;
			},
			hasNext: function() {
				return cur <= to;
			}
		};
	}

	public static function getModchart() {
		var state:PlayState = FlxG.state is PlayState ? cast FlxG.state : null;
		if (state == null)
			return null;

		@:privateAccess var notefield = state.notefield;
		if (notefield.modchart == null) {
			notefield.modchart = new ModchartManager();
			notefield.modchart.parent = notefield;
		}
		return notefield.modchart;
	}

	public static function apply(to:Script) {
		if (to.interp == null)
			return;

		inline function set(name:String, val:Dynamic)
			to.set(name, val);
		inline function setClass(cls:Class<Dynamic>) {
			var name = Type.getClassName(cls);
			to.set(name.substring(name.lastIndexOf(".") + 1, name.length), cls);
		}

		// id say duct tape but this is just lazyness I HAVE THE DAMN REPOSITORY -srt
		@:privateAccess to.interp.binops.set("...", (e1, e2) -> range(to.interp.expr(e1), to.interp.expr(e2) - 1, 1));

		var game = FlxG.state is PlayState ? cast FlxG.state : null;
		set('game', game);
		set('state', FlxG.state);
		set("range", range);

		// set('lerpColor', function(from:FlxColor, to:FlxColor, ratio:Float){
		// 	return FlxColor.fromRGBFloat(FlxMath.lerp(from.redFloat, to.redFloat, ratio), FlxMath.lerp(from.greenFloat, to.greenFloat, ratio),
		// 		FlxMath.lerp(from.blueFloat, to.blueFloat, ratio), FlxMath.lerp(from.alphaFloat, to.alphaFloat, ratio));
		// });
		set('lerpColor', FlxColor.interpolate);

		set("Std", Std);
		set("Math", Math);

		setClass(funkin.objects.FunkinSprite);
		setClass(funkin.objects.FunkinSpriteGroup);
		setClass(funkin.core.FunkinAssets);
		setClass(funkin.core.Settings);
		setClass(funkin.core.Controls);
		setClass(funkin.core.Util);

		setClass(nevermore.core.Assets);
		setClass(nevermore.core.Conductor);
		setClass(nevermore.modchart.drawing.ProxyField);

		setClass(FlxG);
		setClass(flixel.FlxSprite);
		setClass(flixel.FlxCamera);
		setClass(flixel.text.FlxText);
		setClass(flixel.util.FlxTimer);
		setClass(flixel.tweens.FlxTween);
		setClass(flixel.tweens.FlxEase);
		setClass(flixel.math.FlxMath);
		setClass(flixel.group.FlxGroup);
		setClass(flixel.group.FlxSpriteGroup);
		setClass(flixel.math.FlxPoint.FlxBasePoint);

		if (game == null)
			return; // maybe one day getModchart will become smarter but

		set('addSV', function(time:Float, mult:Float) {
			game.chart.scrollVelocities.push({
				time: time,
				multiplier: mult
			});
		});

		set('getModchartManager', getModchart);
		set('get', function(name:String, ?strumline:Int = 0) {
			return getModchart().get(name, strumline);
		});
		set('setNow', function(name:String, value:Float, ?strumline:Int = -1) {
			getModchart().setNow(name, value, strumline);
		});
		set('setAt', function(beat:Float, name:String, value:Float, ?strumline:Int = -1) {
			getModchart().setAt(beat, name, value, strumline);
		});
		set('setMultiAt', function(beat:Float, values:Dynamic, ?strumline:Int = -1) {
			getModchart().setMultiAt(beat, values, strumline);
		});
		set('easeNow', function(length:Float, name:String, value:Float, ?ease:Float->Float, ?strumline:Int = -1) {
			getModchart().easeNow(length, name, value, ease, strumline);
		});
		set('easeAt', function(beat:Float, length:Float, name:String, value:Float, ?ease:Float->Float, ?strumline:Int = -1, ?startVal:Float) {
			getModchart().easeAt(beat, length, name, value, ease, strumline, startVal);
		});
		set('easeMultiAt', function(beat:Float, length:Float, values:Dynamic, ?ease:Float->Float, ?strumline:Int = -1, ?startVals:Dynamic) {
			getModchart().easeMultiAt(beat, length, values, ease, strumline, startVals);
		});
		set('oneshotFuncAt', function(beat:Float, func:Float->Float->Void) {
			getModchart().oneshotFuncAt(beat, func);
		});
		set('continuousFuncAt', function(beat:Float, length:Float, func:Float->Float->Void) {
			getModchart().continuousFuncAt(beat, length, func);
		});
		set('easedFuncAt', function(beat:Float, length:Float, func:Float->Float->Void, ?ease:Float->Float, ?startVal:Float, ?endVal:Float) {
			getModchart().easedFuncAt(beat, length, func, ease, startVal, endVal);
		});
		set('makeAux', function(name:String, ?defaultValue:Int = 0) {
			getModchart().makeAux(name, defaultValue);
		});
		set('makeNode', function(inputs:Array<String>, func:NodeFunc, ?outputs:Array<String>) {
			getModchart().makeNode(inputs, func, outputs);
		});
	}

}