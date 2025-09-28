package;

import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import funkin.backend.FPSCounter;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;

class Main extends Sprite {
	public static var fpsCounter:FPSCounter;

	public static var engineVersion:String = '1.0.0';
	public function new() {
		super();

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		addChild(new FlxGame(InitState, 0, 0, 120, true));
		addChild(fpsCounter = new FPSCounter(10, 10, 12));
		fpsCounter.visible = Settings.data.fpsCounter;

		@:privateAccess FlxG.keys._nativeCorrection.set("0_43", FlxKey.PLUS);
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
		Controls.load();
		Settings.load();
		Scores.load();
		DiscordClient.start();
		Addons.load();
		Meta.cacheFiles();
		Alphabet.loadData();
		funkin.modchart.ModchartManager.setupRedirects();
		funkin.backend.LanguageHandler.loadTranslations();
		funkin.backend.LanguageHandler.setLanguage(Settings.data.language);

		FlxG.fullscreen = Settings.data.fullscreen;
		FlxG.fixedTimestep = false;
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
		FlxG.game.focusLostFramerate = Math.floor(Settings.data.framerate / 4);
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;
		FlxG.autoPause = Settings.data.autoPause;
		FlxAudioHandler.init();

		FlxG.sound.volumeHandler = (v:Float) -> {
			FlxG.save.data.volume = v;
			FlxAudioHandler.volume = v;

			@:privateAccess
			FlxAudioHandler.music._audioBackend.updateVolume();

			for (al in FlxAudioHandler.audioList){
				@:privateAccess
				al._audioBackend.updateVolume();
			}
		}
		FlxG.sound.volumeUpKeys = Controls.binds["volume_up"];
		FlxG.sound.volumeDownKeys = Controls.binds["volume_down"];
		FlxG.sound.muteKeys = Controls.binds["volume_mute"];

		FlxG.signals.preStateSwitch.add(()->{
			Conductor.reset();
			FlxAudioHandler.checkStoredSounds();
		});

		FlxG.sound.volume = FlxG.save.data.volume ?? 1.0;
		FlxG.sound.muted = FlxG.save.data.muted ?? false;
		FlxG.sound.volumeHandler(FlxG.sound.muted ? 0 : FlxG.sound.volume);
		FlxG.game.soundTray.updateWithSettings();

		var isClosing:Bool = false;
		openfl.Lib.application.window.onClose.add(function () {
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.data.muted = FlxG.sound.muted;
			FlxG.save.flush();
			FlxG.save.close();
        }, true);

		FlxG.plugins.add(new funkin.backend.Conductor());
	}
}
