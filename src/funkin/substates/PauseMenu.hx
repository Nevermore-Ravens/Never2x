package funkin.substates;

import funkin.states.OptionsState;

class PauseMenu extends flixel.FlxSubState {
	var options:Array<String> = ['Resume', 'Restart', 'Options', 'Exit to Menu'];
	var optionGrp:FlxTypedSpriteGroup<Alphabet>;

	var difficulty:String;
	var songName:String;
	var deaths:Int;

	var music:FlxSound;
	public static var musicPath:String = Settings.data.pauseMusic;
	public static var openCount:Int = 0;

	public static var wentToOptions:Bool = false;
	public var changingDifficulty:Bool = false;

	var curSelected:Int = 0;

	public function new(song:String, difficulty:String, deaths:Int) {
		super();
		this.songName = song;
		this.difficulty = difficulty;
		this.deaths = deaths;
	}

	override function create():Void {
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = false);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = false);

		if (Difficulty.list.length > 1) options.insert(3, 'Change Difficulty');

		if (Settings.data.pauseType != 'Unlimited') {
			openCount++;
			if (openCount > 3 || Settings.data.pauseType == 'Disabled') options.remove('Resume');
		}

		if (musicPath != 'None') {
			/*if (musicPath == 'Song Instrumental') {
				@:privateAccess
				music = Util.makeSound(Conductor.inst._sound, 0, true);
			} else */music = Util.makeSound(Assets.audio("music/" + musicPath), 0);

			music.time = FlxG.random.float(0, music.length * 0.75);
			music.play();
		}

		FlxG.autoPause = false;
		Conductor.pause();

		var bg:FunkinSprite = new FunkinSprite().makeGraphic(1, 1, FlxColour.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		add(bg);

		var song:FlxText = new FlxText(20, 15, 0, songName, 32);
		song.font = Assets.getPath("fonts/vcr.ttf");
		song.x = FlxG.width - (song.width + 20);
		song.alpha = 0;
		add(song);

		var songDifficulty:FlxText = new FlxText(20, 47, 0, difficulty.toUpperCase(), 32);
		songDifficulty.font = Assets.getPath('fonts/vcr.ttf');
		songDifficulty.x = FlxG.width - (songDifficulty.width + 20);
		songDifficulty.alpha = 0;
		add(songDifficulty);

		var blueballed:FlxText = new FlxText(20, 15 + 64, 0, 'Blueballed: $deaths', 32);
		blueballed.font = Assets.getPath('fonts/vcr.ttf');
		blueballed.x = FlxG.width - (blueballed.width + 20);
		blueballed.alpha = 0;
		add(blueballed);

		add(optionGrp = new FlxTypedSpriteGroup<Alphabet>());

		regenerateOptions(options);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(song, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(songDifficulty, {alpha: 1, y: songDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballed, {alpha: 1, y: blueballed.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		changeSelection();

		FlxG.mouse.visible = true;
	}

	function changeSelection(?dir:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + dir, 0, optionGrp.length - 1);

    	for (index => obj in optionGrp.members) {
			obj.targetY = index - curSelected;
			obj.alpha = curSelected == index ? 1 : 0.5;
		}

		FlxG.sound.play(Assets.audio('sfx/scroll'));
	}

	function regenerateOptions(list:Array<String>) {
		optionGrp.clear();

		for (index => option in list) {
			final alphabet:Alphabet = optionGrp.add(new Alphabet(90, 320, option, BOLD, LEFT));
			alphabet.isMenuItem = true;
			alphabet.targetY = index;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (music != null && music.volume < Settings.data.pauseMusicVolume) music.volume += elapsed;

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) changeSelection(downJustPressed ? 1 : -1);

		if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

		if (Controls.justPressed('back')) {
			if (changingDifficulty) {
				regenerateOptions(options);
				changingDifficulty = false;
				curSelected = 0;
				changeSelection();
			} else resume();
		}

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			if (changingDifficulty) {
				Difficulty.current = Difficulty.list[curSelected];
				FunkinState.switchState(new PlayState());
				FlxG.autoPause = Settings.data.autoPause;
				close();
			} else switch (options[curSelected]) {
				case 'Resume': resume();
					
				case 'Restart': 
					music.stop();
					FlxG.mouse.visible = false;
					FunkinState.resetState();
					FlxG.autoPause = Settings.data.autoPause;

				case 'Options':
					music.stop();
					Conductor.stop();
					Conductor.reset();
					Util.toMenu(new FreeplayState());
					FunkinState.switchState(new OptionsState());
					OptionsState.inPlayState = true;

				case 'Change Difficulty': 
					regenerateOptions(Difficulty.list);
					changingDifficulty = true;
					curSelected = 0;
					changeSelection();

				case 'Exit to Menu':
					music.stop();
					PlayState.self.endSong(true);
					FlxG.autoPause = Settings.data.autoPause;
			}
		}
	}

	function resume() {
		music.stop();
		Conductor.resume();
		FlxG.mouse.visible = false;
		//parent.persistentUpdate = true;
		close();
		FlxG.autoPause = Settings.data.autoPause;
	}

	override function close() {
		PauseMenu.wentToOptions = false; // reset

		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = true);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = true);

		super.close();
	}
}