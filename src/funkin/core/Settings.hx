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
	var strumGlow:String = 'Note';
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
	var pauseType:String = 'Unlimited';
	var pauseMusic:String = 'Breakfast';
	var pauseMusicVolume:Float = 0.7;

	var customColumns:Array<FlxColor> = [0xFFD17ABB, 0xFF85ADE4, 0xFF2DD4BA, 0xFFC96F78];
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
	var holdGrain:Int = 5;
	var antialiasing:Bool = true;
	var audioStreams:Bool = true;
	var reducedQuality:Bool = false;
	var shaders:Bool = true;
	var gpuCache:Bool = true;
	var fullscreen:Bool = false;
	var reflections:Bool = true;
	var videos:Bool = true;

	// visuals (that don't affect performance)
	var flashingLights:Bool = true;
	var noteSkin:String = 'funkin';
	var noteSkinStyle:String = 'default';
	var noteSplashSkin:String = 'classic';
	var unglowOnAnimFinish:Bool = true;
	var gameVisibility:Int = 100;
	var cameraZooms:String = 'Default';
	var simplePopup:Bool = false;
	var popupOnField:Bool = false;
	var popupPosSafety:Bool = false;
	var judgementPos:Array<Float> = [530, 350];
	var comboPos:Array<Float> = [450, 420];
	var judgeScale:Float = 1.0;
	var comboScale:Float = 1.0;
	var judgementAlpha:Float = 1;
	var judgementCounter:Bool = false;
	var hideTightestJudge:Bool = false;
	var comboAlpha:Float = 1;
	var healthBarAlpha:Float = 1;
	var language:String = 'en-US';
	var infoCounter:Bool = false;
	var transitions:Bool = true;
	var timeText:Bool = true;
	var hideHUD:Bool = false;
	var lyrics:Bool = true;

	// miscellaneous
	var discordRPC:Bool = true;
	var autoPause:Bool = true;

	var gameplayModifiers:Map<String, Dynamic> = [
		'playbackRate' => 1.0,
		'minClearType' => "Clear",
		'noFail' => false,
		'autoplay' => false,
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
		Nevermore.settings.receptorGlow = data.strumGlow;
		//Nevermore.settings.quantization = data.quantization;
	}

	public static inline function reset(?saveToDisk:Bool = false) {
		data = {};
		updateNevermore();

		if (saveToDisk) save();
	}

	public static function validate() {
		var langs = Languages.getIDs();
		if (!langs.contains(data.language)) {
			data.language = langs.contains(default_data.language) ? default_data.language : langs[0];
			Sys.println("Invalid language! Resetting value in settings.");
		}

		if (!["Default", "Off"].contains(data.cameraZooms)) {
			data.cameraZooms = (data.cameraZooms.toLowerCase() == "false") ? "Off" : "Default";
			Sys.println("Invalid camera zoom type! Adjusting value in settings.");
		}

		if (data.strumGlow == "Per-Note")
			data.strumGlow = "Note";
		if (data.quantColouring != "None" && !data.quantColouring.startsWith("Custom") && !NoteColor.quantList.exists(data.quantColouring)) {
			data.quantColouring = default_data.quantColouring;
			Sys.print("Invalid note palette! Resetting value in settings.");
		}

		var noteSkinMap = NoteStyling.getList();
		if (!noteSkinMap.exists(data.noteSkin)) {
			var foundLowercase = false;
			for (key in noteSkinMap.keys()) {
                if (key.toLowerCase() == data.noteSkin.toLowerCase()) {
                    data.noteSkin = key;
					foundLowercase = true;
                    break;
                }
            }

			if (foundLowercase)
				data.noteSkin = noteSkinMap.exists(default_data.noteSkin) ? default_data.noteSkin : noteSkinMap.keys().next();
			Sys.println(foundLowercase ? "Incorrect casing! Fixing value in settings." : "Invalid noteskin! Resetting value in settings.");
		}
		if (data.noteSkinStyle != "default" && !noteSkinMap[data.noteSkin].styleKeys.contains(data.noteSkinStyle)) {
			data.noteSkinStyle = default_data.noteSkinStyle;
			Sys.print("Invalid note skin style! Resetting value in settings.");
		}

		var modifierAlias = ["autoplay" => "botplay"];
		for (key in default_data.gameplayModifiers.keys()) {
			if (!data.gameplayModifiers.exists(key)) {
				if (modifierAlias.exists(key) && data.gameplayModifiers.exists(modifierAlias[key])) {
					data.gameplayModifiers.set(key, data.gameplayModifiers[modifierAlias[key]]);
					data.gameplayModifiers.remove(modifierAlias[key]);
					Sys.println('redirecting modifier ${modifierAlias[key]} to $key');
				} else {
					data.gameplayModifiers.set(key, default_data.gameplayModifiers[key]);
					Sys.println('regrabbing modifier $key');
				}
			}
		}

		/*final possibleNotesplashes: Array<String> = ['none'];
		for (splashPath in Paths.readDirectory("data/noteSplashes"))
			if (splashPath.endsWith(".json5") || splashPath.endsWith(".json")) {
				var splashName:String = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(splashPath));
				if(possibleNotesplashes.contains(splashName)) continue;
				possibleNotesplashes.insert(0, splashName);
			}

		if (!possibleNotesplashes.contains(data.noteSplashSkin)) {
			data.noteSplashSkin = "classic";
			Sys.println("Note splash doesn't exist! Resetting value in settings.");
		}*/

		updateNevermore();
	}
}
