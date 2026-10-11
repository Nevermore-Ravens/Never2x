package;

import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import funkin.core.LanguageHandler;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import nevermore.InfoCounter;
import funkin.core.chart.*;
import nevermore.core.Judgement;
import funkin.states.*;
import funkin.core.*;
import nevermore.core.HitWindows;
import funkin.ui.Alphabet;

import flixel.FlxG;
import sys.FileSystem;
import sys.io.File;

using StringTools;

#if (linux && !debug)
@:cppInclude('../../_external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
#if (cpp && windows)
// Fix cyrillic characters in terminal output
@:cppInclude("windows.h")
#end
class Never2x extends Sprite {
	public static var infoCounter:InfoCounter;

	public static var version:String = '1.0.0';

	public function new() {
		super();

		#if (cpp && windows)
		// Fix cyrillic characters in terminal output
		untyped __cpp__('SetConsoleOutputCP(CP_UTF8)');
		#end

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		addChild(new flixel.FlxGame(InitState, 0, 0, 120, true));
		addChild(infoCounter = new InfoCounter());
		infoCounter.visible = Settings.data.infoCounter;

		@:privateAccess FlxG.keys._nativeCorrection.set("0_43", FlxKey.PLUS);
	}

	override function __enterFrame(delta:Int) {
		FlxG.game.__enterFrame(delta);
		infoCounter.__enterFrame(delta);
		
		@:privateAccess
		FlxG.mouse.enabled = !FlxG.game._lostFocus;
	}

	#if windows
	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
	@:noCompletion override function __hitTest(_, _, _, _, _, _):Bool return false;
	@:noCompletion override function __hitTestHitArea(_, _, _, _, _, _):Bool return false;
	@:noCompletion override function __hitTestMask(_, _):Bool return false;
	#end

	function onCrash(e:UncaughtErrorEvent):Void {
		e.preventDefault();
		e.stopImmediatePropagation();

		var errMsg:String = '${e.error}\n\n';
		var date:String = '${Date.now()}'.replace(":", "'");

		for (stackItem in CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(_, file, line, _): errMsg += 'Called from $file:$line\n';
				default: Sys.println(stackItem);
			}
		}

		errMsg += '\nExtra Info:\n';
		errMsg += 'Operating System: ${Util.getOperatingSystem()}\nTarget: ${Util.getTarget()}\n\n';

		final defines:Map<String, Dynamic> = _external.CompilerDefines.list;
		errMsg += 'Haxe: ${defines['haxe']}\nFlixel: ${defines['flixel']}\nOpenFL: ${defines['openfl']}\nLime: ${defines['lime']}';

		if (!FileSystem.exists('./crash/')) FileSystem.createDirectory('./crash/');

		File.saveContent('./crash/$date.txt', '$errMsg\n');
		Sys.println('\n$errMsg');
		lime.app.Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}
}

class InitState extends flixel.FlxState {
	override function create():Void {
		setDefines();
		flixel.FlxG.switchState(new TitleState());
	}

	private function startNevermore() {
		nevermore.Nevermore.init();
		moonchart.Moonchart.init();

		moonchart.backend.FormatDetector.getFormatData(QUAVER).handler = CustomQuaver;
		moonchart.backend.FormatDetector.getFormatData(STEPMANIA).handler = CustomStepMania;
		moonchart.backend.FormatDetector.getFormatData(QUAVER).handler = CustomSSC;
		nevermore.core.Song.parser = new SongParser();

		Judgement.register('Never2x', [
			{
				name: 'Killer',
				window: HitWindows.current[0],
				health: 1.25,
				color: 0xFF8ACDFF
			},
			{
				name: 'Sick',
				window: HitWindows.current[1],
				health: 1,
				color: 0xFFFFED5E
			},
			{
				name: 'Good',
				window: HitWindows.current[2],
				health: 0.25,
				color: 0xFF5EF95E
			},
			{
				name: 'Bad',
				window: HitWindows.current[3],
				health: -5,
				color: 0xFFBF7BE9
			},
			{
				name: 'Shit',
				breaksCombo: true,
				window: HitWindows.current[4],
				health: -10,
				color: 0xFF5E3596
			}
		]);
		Judgement.type = 'Never2x';
	}

	private function setDefines() {
		startNevermore();
		Addons.init();

		Controls.load();
		Settings.load();
		Scores.load();
		DiscordClient.start();
		Meta.cacheFiles();
		Alphabet.loadData();
		LanguageHandler.loadTranslations();

		LanguageHandler.setLanguage(Settings.data.language);

		FlxG.fullscreen = Settings.data.fullscreen;
		FlxG.fixedTimestep = false;
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
		FlxG.game.focusLostFramerate = Math.floor(Settings.data.framerate / 4);
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;
		FlxG.autoPause = Settings.data.autoPause;

		FlxG.sound.volumeUpKeys = Controls.binds["volume_up"];
		FlxG.sound.volumeDownKeys = Controls.binds["volume_down"];
		FlxG.sound.muteKeys = Controls.binds["volume_mute"];

		FlxG.sound.volume = FlxG.save.data.volume ?? 1.0;
		FlxG.sound.muted = FlxG.save.data.muted ?? false;
		//FlxG.sound.volumeHandler(FlxG.sound.muted ? 0 : FlxG.sound.volume);
		//FlxG.game.soundTray.updateWithSettings();

		openfl.Lib.application.window.onClose.add(function () {
			if (FlxG.state is funkin.states.OptionsState) {
				Controls.save();
				Settings.save();
			}

			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.data.muted = FlxG.sound.muted;
			FlxG.save.flush();
			FlxG.save.close();
        }, true);

		FlxG.plugins.add(new funkin.substates.AddonsMenu());
	}
}
