package funkin.core;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import nevermore.Nevermore;

@:structInit
@:publicFields
class SaveVariables {
	// for readability
	var downscroll(get, never):Bool;
	function get_downscroll():Bool return scrollDirection == DOWN;

	// gameplay
	var scrollDirection:String = UP;
	var quantColouring:String = "None";
	var strumGlow:String = 'Per-Note';
	var scrollSpeed:Float = 3;
	var strumSize:Float = 1;
	var centeredNotes:Bool = false;
	var laneUnderlay:Float = 0;
	var opponentNotes:Bool = true;
	var hideAcc:Bool = false;
	var comboTinting:String = 'Off';
	var ghostTapping:Bool = true;
	var metronome:Bool = false;
	var canReset:Bool = true;
	var inputOffset:Float = 0;
	var assistTicks:Bool = false;
	var accuracyType:String = 'Simple';
	var hitErrorBar:Bool = true;
	var modcharts:Bool = true;
	var pauseType:String = 'Unlimited';
	var pauseMusic:String = 'Breakfast';
	var pauseMusicVolume:Float = 0.7;

	var customColumns:Array<FlxColor> = [0xFFED34A9, 0xFF9653D6, 0xFF596AF6, 0xFF69E4B5];
	var customQuants:Array<FlxColor> = [
		0xFFED34A9,
		0xFF596AF6,
		0xFF9653D6,
		0xFF69E4B5,
		0xFF9581A8,
		0xFF9653D6,
		0xFFFFFCA3,
		0xFF9653D6,
		0xFF52B6EB,
		0xFF9581A8,
		0xFF9581A8
	];

	// graphics (that affect performance)
	var framerate:Int = 60;
	var holdGrain:Int = 1;
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
	var noteSkinStyle:String = 'default';
	var noteSplashSkin:String = 'classic';
	var unglowOnAnimFinish:Bool = true;
	var gameVisibility:Int = 100;
	var cameraZooms:String = 'Default';
	var popupCenter:String = "Top";
	var judgementAlpha:Float = 1;
	var judgementCounter:Bool = false;
	var hideHighest:Bool = false;
	var comboAlpha:Float = 1;
	var healthBarAlpha:Float = 1;
	var language:String = 'English';
	var infoCounter:Bool = true;
	var transitions:Bool = true;
	var timeText:Bool = true;
	var hideHUD:Bool = false;
	var lyrics:Bool = true;
	var notesMoveCamera:Bool = false;

	// miscellaneous
	var discordRPC:Bool = true;
	var autoPause:Bool = true;

	var gameplayModifiers:Map<String, Dynamic> = [
		'playbackRate' => 1.0,
		'minClearType' => "Clear",
		'noFail' => false,
		'botplay' => false,
		'mirroredNotes' => false,
		'randomizedNotes' => false,
		'modcharts' => true, // for cam we can have this false default but i think on base n2x this should be true -marsh
		'svs' => true,
		'sustains' => true,
		'blind' => false,
		'playingSide' => 'Default'
	];

	// for addons
	var addonsOrder:Array<String> = [];
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
			if (!fields.contains(i) || i == "gameplayModifiers") continue;

			if (Reflect.hasField(data, 'set_$i')) Reflect.setProperty(data, i, Reflect.field(FlxG.save.data, i));
			else Reflect.setField(data, i, Reflect.field(FlxG.save.data, i));
		}

		if (FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(refreshRate * 2);
		}
	
		if (FlxG.save.data.gameplayModifiers != null) {
			final map:Map<String, Dynamic> = FlxG.save.data.gameplayModifiers;
			for (name => value in map) data.gameplayModifiers.set(name, value);
		}

		#if DISCORD_ALLOWED DiscordClient.check(); #end

		updateNevermore();
	}

	public static function updateNevermore() {
		Nevermore.settings.inputOffset = data.inputOffset;
		Nevermore.settings.holdGrain = data.holdGrain;
		//Nevermore.settings.quantization = data.quantization;
	}

	public static inline function reset(?saveToDisk:Bool = false) {
		data = {};
		updateNevermore();

		if (saveToDisk) save();
	}

	public static function validate() {
		if (!funkin.core.LanguageHandler.getLanguages().contains(data.language)) {
			data.language = "English";
			Sys.println("Invalid language! Resetting value in settings.");
		}

		if (!["Default", "Legacy", "Off"].contains(data.cameraZooms)) {
			data.cameraZooms = (data.cameraZooms.toLowerCase() == "false") ? "Off" : "Default";
			Sys.println("Recieved bool instead of string in camera zooms! Adjusting value in settings.");
		}

		final possibleNotesplashes: Array<String> = ['none'];
		for (splashPath in Paths.readDirectory("data/noteSplashes"))
			if (splashPath.endsWith(".json5") || splashPath.endsWith(".json")) {
				var splashName:String = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(splashPath));
				if(possibleNotesplashes.contains(splashName)) continue;
				possibleNotesplashes.insert(0, splashName);
			}

		if (!possibleNotesplashes.contains(data.noteSplashSkin)) {
			data.noteSplashSkin = "classic";
			Sys.println("Note splash doesn't exist! Resetting value in settings.");
		}
	}
}
