package;

import lime.app.Application;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
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

		Application.current.frameProfile = LowEnergy;
		Application.current.frameOptions = {
			busyWait: Off,
			timePrecision: Millisecond,

			// NOTE FOR LATER:
			// currently with lime 8.4.0 frame throttling is a bit fucky
			// too much pressure on rendering causes inputs (including the mouse) to slow down or get delayed
			// (you can replicate this in any heavy mod that uses shaders or whatever
			// like mario's madness or indie cross
			// but newer lime kinda makes it more likely to happen with the new main loop
			//
			// uncapMode: Soft
			//
			// this fixes it at the cost of fps yknow
			// not being capped anymore
			// im not sure how to fix this so i'll just leave this note here until i figure it out more
		};
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
		//flixel.FlxG.switchState(new TitleState());
		flixel.FlxG.switchState(new StartupState());
	}

	private function startNevermore() {
		Judgement.register('Never2x', [
			{
				name: 'Killer',
				health: 1.25,
				color: 0xFF8ACDFF
			},
			{
				name: 'Sick',
				health: 1,
				color: 0xFFFFED5E
			},
			{
				name: 'Good',
				health: 0.25,
				color: 0xFF5EF95E
			},
			{
				name: 'Bad',
				health: -5,
				color: 0xFFBF7BE9
			},
			{
				name: 'Shit',
				breaksCombo: true,
				health: -10,
				color: 0xFF5E3596
			}
		]);

		nevermore.core.Song.parser = new SongParser();
		nevermore.Nevermore.init({
			judgements: 'Never2x',
			// vv these are custom and modified by n2x itself
			//quants: 'StepMania',
			//laneColors: 'Custom'
		});
		moonchart.Moonchart.init();

		moonchart.backend.FormatDetector.getFormatData(QUAVER).handler = CustomQuaver;
		//moonchart.backend.FormatDetector.getFormatData(STEPMANIA).handler = CustomStepMania;
		moonchart.backend.FormatDetector.getFormatData(STEPMANIA_SHARK).handler = CustomSSC;

		nevermore.skins.BasicNoteskin.scale = 0.65;
	}

	private function setDefines() {
		startNevermore();

		Controls.load();
		Settings.load();
		Addons.init();
		
		Scores.load();
		DiscordClient.start();
		Meta.cacheFiles();
		Alphabet.loadData();
		
		Languages.init();
		Languages.change(Settings.data.language);

		FlxG.fullscreen = Settings.data.fullscreen;
		FlxG.fixedTimestep = false;
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
		FlxG.game.focusLostFramerate = Math.floor(Settings.data.framerate / 4);
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;
		FlxG.autoPause = Settings.data.autoPause;

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
