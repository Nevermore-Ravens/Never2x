package;

import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import funkin.backend.LanguageHandler;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import funkin.FunkinCounter;

#if (linux && !debug)
@:cppInclude('../../_external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
#if (cpp && windows)
// Fix cyrillic characters in terminal output
@:cppInclude("windows.h")
#end
class Main extends Sprite {
	public static var infoCounter:FunkinCounter;

	public static var engineVersion:String = '1.0.0';
	/**
	 * Tween Manager that works regardless FlxG.timeScale
	 */
	public static var tweenManager:FlxTweenManager = null;

	public function new() {
		super();

		#if (cpp && windows)
		// Fix cyrillic characters in terminal output
		untyped __cpp__('SetConsoleOutputCP(CP_UTF8)');
		#end

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		addChild(new FlxGame(InitState, 0, 0, 120, true));
		addChild(infoCounter = new FunkinCounter(10, 10, 12));
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

	private function setDefines() {
		nevermore.Nevermore.init();
		moonchart.Moonchart.init();

		Main.tweenManager = new FlxTweenManager();
		Controls.load();
		Settings.load();
		Scores.load();
		DiscordClient.start();
		Addons.load();
		Meta.cacheFiles();
		Alphabet.loadData();
		#if MODCHARTS_ALLOWED funkin.modchart.ModchartManager.setupRedirects(); #end
		LanguageHandler.loadTranslations();

		Settings.validate();
		LanguageHandler.setLanguage(Settings.data.language);

		Judgement.reset();

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

		FlxG.signals.preUpdate.add(() -> {
			Main.tweenManager.update(FlxG.elapsed / FlxG.timeScale);
		});

		FlxG.signals.preStateSwitch.add(() -> {
			// this if is duct tape in case we get crashes again but hopefully we're getting a better asset system
			// @:privateAccess if (Type.getClass(FlxG.game._requestedState) != Type.getClass(FlxG.state))
			 	Paths.clearTracking();
			NoteSkin.recache();
		});
		FlxG.signals.postStateSwitch.add(()->{
			Paths.clearUnusedMemory();
		});

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
