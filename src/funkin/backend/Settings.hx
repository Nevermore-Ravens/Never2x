package funkin.backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

@:structInit
@:publicFields
class SaveVariables {
	// for readability/backwards compatability
	var downscroll(get, never):Bool;
	function get_downscroll():Bool return scrollDirection.toLowerCase() == 'down';

	// gameplay
	var scrollDirection:String = 'Up';
	var quantColouring:String = "None";
	var strumGlow:String = 'Per-Note';
	var scrollSpeed:Float = 3.35;
	var centeredNotes:Bool = false;
	var opponentNotes:Bool = true;
	var hideAcc:Bool = false;
	var comboTinting:String = 'Off';
	var ghostTapping:Bool = true;
	var metronome:Bool = false;
	var canReset:Bool = true;
	var noteOffset:Float = 0;
	var assistClaps:Bool = false;
	var hitErrorBar:Bool = true;
	var modcharts:Bool = true;
	var pauseType:String = 'Unlimited';
	var pauseMusic:String = 'Breakfast';
	var pauseMusicVolume:Float = 0.7;

	// graphics (that affect performance)
	var framerate:ShortUInt = 60;
	var holdGrain:ByteUInt = 1;
	var antialiasing:Bool = true;
	var audioStreams:Bool = true;
	var reducedQuality:Bool = false;
	var shaders:Bool = true;
	var gpuCache:Bool = true;
	var fullscreen:Bool = false;
	var closeAnimation = true;
	var reflections:Bool = true;
	var videos:Bool = true;

	// visuals (that don't affect performance)
	var flashingLights:Bool = true;
	var noteSkin:String = 'camv2';
	var noteSplashSkin:String = 'classic';
	var unglowOnAnimFinish:Bool = true;
	var gameVisibility:ByteUInt = 100;
	var cameraZooms:String = 'Default';
	var popupCenter:String = "Top";
	var judgementAlpha:Float = 1;
	var judgementCounter:Bool = false;
	var comboAlpha:Float = 1;
	var healthBarAlpha:Float = 1;
	var language:String = 'English';
	var fpsCounter:Bool = true;
	var transitions:Bool = true;
	var timeBarType:String = 'Disabled';
	var hideHUD:Bool = false;
	var lyrics:Bool = true;
	var notesMoveCamera:Bool = false;

	// miscellaneous
	var discordRPC:Bool = false;
	var autoPause:Bool = true;

	var gameplayModifiers:Map<String, Dynamic> = [
		'playbackRate' => 1.0,
		'instakill' => false,
		'onlySicks' => false,
		'noFail' => false,
		'botplay' => false,
		'mirroredNotes' => false,
		'randomizedNotes' => false,
		'modcharts' => false,
		'sustains' => true,
		'blind' => false,
		'playingSide' => 'Default'
	];

	// for addons
	var addonsOff:Array<String> = [];
}

class Settings {
	public static final default_data:SaveVariables = {};
	public static var data:SaveVariables = {};

	public static function save() {
		for (key in Reflect.fields(data)) {
			// ignores variables with getters
			if (Reflect.hasField(data, 'get_$key')) continue;
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}

		FlxG.save.flush();
	}

	public static function load() {
		FlxG.save.bind('camellia', Util.getSavePath());

		final fields:Array<String> = Type.getInstanceFields(SaveVariables);
		for (i in Reflect.fields(FlxG.save.data)) {
			if (!fields.contains(i)) continue;

			if (Reflect.hasField(data, 'set_$i')) Reflect.setProperty(data, i, Reflect.field(FlxG.save.data, i));
			else Reflect.setField(data, i, Reflect.field(FlxG.save.data, i));
		}

		if (FlxG.save.data.framerate == null) {
			final refreshRate:ShortUInt = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate * 2, 60, 240));
		}
	
		if (FlxG.save.data.gameplayModifiers != null) {
			final map:Map<String, Dynamic> = FlxG.save.data.gameplayModifiers;
			for (name => value in map) data.gameplayModifiers.set(name, value);
		}

		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	public static inline function reset() {
		data = default_data;
	}
}
