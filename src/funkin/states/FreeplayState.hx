package funkin.states;

import funkin.states.OptionsState;
import funkin.objects.menu.OptionList;
import funkin.objects.CharIcon;

import flixel.util.FlxDestroyUtil;

class Modifier extends Option {
	public static final list:Array<Modifier> = [
		new Modifier("Playback Rate", "How fast the game will go.", "playbackRate", FloatOption(0.35, 5.0, 0.05)),
		new Modifier('Playing Side', 'Which side you\'re playing on for the song.', 'playingSide', ListOption(['Default', 'Opponent'])),
		new Modifier("No Fail", "If you'll live even when out of health.", "noFail", BoolOption),
		new Modifier("Min. Clear Type", "The lowest clear type you can have without failing.", "minClearType", ListOption([])),
		new Modifier("Mirrored Notes", "If the chart will flip its notes around.", "mirroredNotes", BoolOption),
		new Modifier("Randomized Notes", "If the game will swap the lanes around.", "randomizedNotes", BoolOption),
		#if MODCHARTS_ALLOWED new Modifier("Modcharts", "If the game will do some wacky stuff with the notes to make it\nlook cooler.", "modcharts", BoolOption), #end
		#if SV_ALLOWED new Modifier("Scroll Velocities", "If the game will allow scroll velocities to be used.", "svs", BoolOption),#end
		new Modifier("Sustains", "If the game will add holds or not.", "sustains", BoolOption),
		new Modifier("Botplay", "If the game will play the chart for you.", "botplay", BoolOption),
		new Modifier('Blind', 'How much of the chart do you remember?', 'blind', BoolOption),
	];

	override function get_value():Dynamic {
		return Settings.data.gameplayModifiers[id];
	}

	override function set_value(v:Dynamic):Dynamic {
		Settings.data.gameplayModifiers[id] = v; // sorry KeyOption no support for u
		onChange(v);
		return v;
	}
}

class FreeplayState extends FunkinState {
	var songList:Array<SongMeta> = [];

	static var curSelected:Int = 0;

	static var curDifficulty:Int;
	static var curDiffName:String = Difficulty.current;
	static var curDiffs:Array<String> = Difficulty.list;

	var grpSongs:FlxTypedSpriteGroup<Alphabet>;
	var grpIcons:FlxTypedSpriteGroup<CharIcon>;

	var modsMenu:OptionList;
	var modsText:FlxText;

	var bg:FlxSprite;
	var intendedColour:Int;

	var intendedAccuracy:Float;
	var lerpAccuracy:Float;

	var lerpScore:Int;
	var intendedScore:Int = 0;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;

	var difficultyText:FlxText;

	var bottomBG:FlxSprite;
	var bottomText:FlxText;

	var draggedOnce:Bool = false;
	var dragging:Bool = false;
	var dragY:Float = -1;

	override function create() {
		super.create();
		persistentUpdate = true;
		WeekData.reload();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Selecting a Song', 'Freeplay');
		#end

		songList.push({
			id: 'random',
			colour: 0xFF000000,
			folder: '',
			icon: 'random',
			difficulties: ['???'],
			weekIdx: 0
		});

		for (i => week in WeekData.list) {
			for (song in week.songs) {
				var diffs:Array<String> = song?.difficulties;
				if (song.difficulties == null || song.difficulties.length == 0) diffs = Difficulty.loadFromWeek(week);

				songList.push({
					id: song.id,
					colour: song.color,
					folder: week.folder,
					icon: song.icon,
					difficulties: diffs,
					weekIdx: i
				});
			}
		}
		curSelected = Std.int(FlxMath.bound(curSelected, 0, songList.length - 1));

		add(bg = new FlxSprite(0, 0, Assets.image('images/menus/desatBG')));
		bg.antialiasing = Settings.data.antialiasing;
		bg.screenCenter();
		bg.color = intendedColour = songList[curSelected].colour;

		add(grpSongs = new FlxTypedSpriteGroup<Alphabet>());
		add(grpIcons = new FlxTypedSpriteGroup<CharIcon>());

		for (index => song in songList) {
			var songName:String = song.id == 'random' ? 'Random' : Meta.load(song.id).songName;
			final alphabet:Alphabet = grpSongs.add(new Alphabet(90, 320, songName));
			alphabet.visible = alphabet.active = false;
			alphabet.targetY = index;
			alphabet.scaleX = Math.min(1, 980 / alphabet.width);
			alphabet.snapToPosition();

			var icon:CharIcon = new CharIcon(song.icon);
			icon.visible = icon.active = false;
			grpIcons.add(icon);
		}

		scoreText = new FlxText(FlxG.width - 384, 5, 0, '', 32);
		scoreText.font = Assets.getPath('fonts/vcr.ttf');
		scoreText.alignment = 'right';

		add(scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000));
		scoreBG.alpha = 0.6;

		add(scoreText);

		add(difficultyText = new FlxText(scoreText.x, scoreText.y + 36, 0, '', 24));
		difficultyText.font = scoreText.font;

		add(modsMenu = new OptionList(FlxG.width - 15, FlxG.height * 0.5 - 275, 650, 550));
		modsMenu.setOptions(cast Modifier.list);
		modsMenu.onOptMove = (cur, left) -> {
			var play:PlayData = Scores.getPlay(songList[curSelected].id, curDiffName);
			intendedScore = play.score;
			intendedAccuracy = play.accuracy;
		};
		modsMenu.onOptEnter = modsMenu.onOptMove.bind(_, true);
		modsMenu.allowMouse = false;
		modsMenu.allowKeys = false;

		add(modsText = new FlxText(modsMenu.x, modsMenu.y + modsMenu.height * 0.5, modsMenu.height, "v [CTRL] - Edit Modifiers v"));
		modsText.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 24, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		modsText.angle = -90;
		modsText.x -= (modsText.width + modsText.height) * 0.5;
		modsText.y -= modsText.height * 0.5;

		changeSelection();
		updateTexts();
	}

	var holdTime:Float;
	var actionPressed:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (actionPressed)
			return;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpAccuracy = FlxMath.lerp(intendedAccuracy, lerpAccuracy, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpAccuracy - intendedAccuracy) <= 0.01) lerpAccuracy = intendedAccuracy;

		var accuracy:Array<String> = '${Util.truncateFloat(lerpAccuracy, 2)}'.split('.');
		if (accuracy.length < 2) accuracy.push(''); // No decimals, add an empty space
		while (accuracy[1].length < 2) accuracy[1] += '0'; // Less than 2 decimals in it, add decimals then
			
		scoreText.text = 'PERSONAL BEST: $lerpScore (${accuracy.join('.')}%)';

		positionStats();

		if (!modsMenu.allowKeys) {
			songControls(elapsed);
			difficultyControls();

			if (Controls.justPressed('accept'))
				enterSong();
	
			if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
				FunkinState.switchState(new MainMenuState());
				actionPressed = true;
			}

			if (FlxG.keys.justPressed.CONTROL || (FlxG.mouse.justPressed && FlxG.mouse.x >= modsText.x + (modsText.width - modsText.height) * 0.5 && FlxG.mouse.y >= modsMenu.y && FlxG.mouse.y <= modsMenu.y + modsMenu.height)) {
				FlxG.sound.play(Assets.audio("sfx/scroll"));
				modsMenu.allowMouse = true;
				modsMenu.allowKeys = true;
			}
		} else if (Controls.justPressed("back") || FlxG.keys.justPressed.CONTROL || FlxG.mouse.justPressedRight || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(modsMenu))) {
			FlxG.sound.play(Assets.audio("sfx/cancel"));
			modsMenu.allowMouse = false;
			modsMenu.allowKeys = false;
		}
		modsMenu.x = FlxMath.lerp(modsMenu.x, (modsMenu.allowKeys ? FlxG.width - 10 - modsMenu.width : FlxG.width - 15), elapsed * 20);
		modsText.setPosition(modsMenu.x - (modsText.width + modsText.height) * 0.5, modsMenu.y + (modsMenu.height - modsText.height) * 0.5);
		updateTexts(elapsed);
	}

	function enterSong() {
		actionPressed = true;
		final oldSelected:Int = curSelected;
		if (songList[curSelected].id == 'random') {
			curSelected = FlxG.random.int(1, songList.length - 1);
			changeSelection();
			curDiffName = curDiffs[FlxG.random.int(0, curDiffs.length - 1)];
		}

		final songID:String = songList[curSelected].id;
		final diff:String = Difficulty.format(curDiffName);
		// final path:String = 'songs/$songID/${Song.getFile(songID, diff)}';
		// if (Paths.exists(path)) {
		if (Song.exists("songs/" + songID, diff)) {
			WeekData.current = songList[curSelected].weekIdx;
			PlayState.songID = songID;
			Difficulty.list = curDiffs;
			Difficulty.current = curDiffName;
			FunkinState.switchState(new PlayState());
			// so that the user doesn't have to scroll all the way back up
			// just to hit "random" again
			curSelected = oldSelected;
		} else {
			persistentUpdate = false;
			trace('Difficulty "$diff" doesn\'t exist for "$songID"');
			actionPressed = false;
			curSelected = oldSelected;
			return;
		}
	}

	function songControls(elapsed:Float) {
		if (songList.length == 1) return;

		if (FlxG.keys.justPressed.HOME) {
			curSelected = 0;
			changeSelection();
			holdTime = 0;
		} else if (FlxG.keys.justPressed.END) {
			curSelected = songList.length - 1;
			changeSelection();
			holdTime = 0;	
		}

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(downJustPressed ? shiftMult : -shiftMult);
			holdTime = 0;
		}

		final downPressed:Bool = Controls.pressed('ui_down');
		if (downPressed || Controls.pressed('ui_up')) {
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				changeSelection((checkNewHold - checkLastHold) * (downPressed ? shiftMult : -shiftMult));
		}

		if (FlxG.mouse.justReleased && !draggedOnce) {for (i => song in grpSongs.members) {
			final icon = grpIcons.members[i];
			if (FlxG.mouse.x < song.x || FlxG.mouse.x > icon.x + icon.width || FlxG.mouse.y < icon.y || FlxG.mouse.y > icon.y + icon.height)
				continue;

			if (i == curSelected)
				enterSong();
			else
				changeSelection(i - curSelected);
		}}
		if (FlxG.mouse.justPressed) {
			dragging = true;
			dragY = FlxG.mouse.screenY;
		} else if (dragging) {
			final dist = Math.round((FlxG.mouse.screenY - dragY) / 75);

			if (dist != 0) {
				draggedOnce = true;
				dragY += 75 * dist;
				changeSelection(-dist);
			}

			if (FlxG.mouse.justReleased) {
				dragging = false;
				draggedOnce = false;
				dragY = -1;
			}
		}

		if (FlxG.mouse.wheel != 0) changeSelection(-shiftMult * FlxG.mouse.wheel, 0.2);
	}

	function difficultyControls() {
		if (curDiffs.length == 1) return;

		final clickDiff = FlxG.mouse.justPressed && FlxG.mouse.x >= scoreBG.x - scoreBG.scale.x * 0.5 && FlxG.mouse.x <= scoreBG.x + scoreBG.scale.x * 0.5 && FlxG.mouse.y >= difficultyText.y && FlxG.mouse.y <= scoreBG.y + scoreBG.height;

		final leftPressed:Bool = Controls.justPressed('ui_left') || (clickDiff && FlxG.mouse.x <= scoreBG.x);
		if (clickDiff || leftPressed || Controls.justPressed('ui_right')) changeDifficulty(leftPressed ? -1 : 1);
	}

	function positionStats() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x * 0.5);
		difficultyText.x = Std.int(scoreBG.x + (scoreBG.width * 0.5));
		difficultyText.x -= difficultyText.width * 0.5;
	}

	function changeSelection(?change:Int = 0, ?volume:Float = 0.4) {
		curSelected = FlxMath.wrap(curSelected + change, 0, songList.length - 1);
		if (volume > 0.0) FlxG.sound.play(Assets.audio('sfx/scroll'), volume);

		for (num => item in grpSongs.members) {
			item.alpha = num == curSelected ? 1 : 0.6;
			grpIcons.members[num].alpha = num == curSelected ? 1 : 0.6;
		}

		Addons.current = Addons.get(songList[curSelected].folder); // sigh

		var newColour:Int = songList[curSelected].colour;
		if (newColour != intendedColour) {
			intendedColour = newColour;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColour);
		}

		curDiffs = songList[curSelected].difficulties;
		curDifficulty = curDiffs.indexOf(curDiffName);
		if (curDifficulty == -1) curDifficulty = 0;
		changeDifficulty();
	}

	function changeDifficulty(?change:Int = 0) {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, curDiffs.length - 1);

		curDiffName = curDiffs[curDifficulty];
		var displayDiff:String = curDiffName.toUpperCase();
		difficultyText.text = curDiffs.length == 1 ? displayDiff : '< $displayDiff >';

		var play:PlayData = Scores.getPlay(songList[curSelected].id, curDiffName);
		intendedScore = play.score;
		intendedAccuracy = play.accuracy;

		positionStats();
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	var lerpSelected:Float = 0.0;
	public function updateTexts(elapsed:Float = 0.0) {
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles) {
			var text:Alphabet = grpSongs.members[i];
			text.visible = text.active = false;
			grpIcons.members[i].visible = false;
		}
		_lastVisibles.resize(0);

		var min:Int = Math.round(FlxMath.bound(lerpSelected - _drawDistance, 0, songList.length));
		var max:Int = Math.round(FlxMath.bound(lerpSelected + _drawDistance, 0, songList.length));
		for (i in min...max) {
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.spawnPos.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.spawnPos.y;

			var icon:CharIcon = grpIcons.members[i];
			icon.visible = true;
			icon.setPosition(item.x + (item.width + (icon.width * 0.05)), item.y - (item.height * 0.5));
			_lastVisibles.push(i);
		}
	}	
}

typedef SongMeta = {
	var id:String;
	var icon:String;
	var colour:FlxColor;
	var folder:String;
	var difficulties:Array<String>;
	var weekIdx:Int;
}