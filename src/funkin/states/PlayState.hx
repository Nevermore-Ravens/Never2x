package funkin.states;

import nevermore.core.Chart;
import nevermore.play.*;
import nevermore.skins.Noteskin;

import funkin.core.scripts.ScriptList;
import funkin.core.chart.EventHandler;
import funkin.core.scoring.*;
import funkin.core.accuracy.*;
import funkin.core.Statistics;
import funkin.ui.play.*;
import funkin.objects.Stage;
import funkin.objects.Character;
import funkin.objects.NoteSplash;
import funkin.substates.PauseMenu;
import funkin.substates.ResultsScreen;
import funkin.substates.FailedMenu;

class PlayState extends FunkinState {
	public static var songID:String = '';
	public static var self:PlayState;
	var chart:Chart;
	var events:EventHandler;
	var playerID:Int = 1;

	var notefield:NoteField;
	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	var noteSkin:String = 'funkin';
	var extraTime:Float = 2500; // 2.5 seconds
	var downscroll:Bool = false;

	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		value = FlxMath.bound(value, 0, 100);
		if (value == 0) death();

		health = value;
		healthBar.updatePercent();

		updateIconStates();
		updateIconPositions();

		return value;
	}

	var iconSpacing:Float = 20;

	var stats:Statistics;
	var scoring:ScoreHandler = new DefaultScoring();
	var accuracy:AccuracyHandler = new DefaultAccuracy();

	var hud:FlxSpriteGroup;
	var infoText:FlxText;
	var judgeSprite:JudgeDisplay;
	var comboSprite:ComboDisplay;

	var stage:Stage;
	var player:Character;
	var enemy:Character;
	var spectator:Character;

	var resetZoom:Bool = true;
	var defaultZoom:Float = 1.0;
	var zoomInterval:Int = 4;
	var zoomStrength:Float = 0.015;

	var camFollow:FlxObject;
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camOther:FlxCamera;

	var scripts:ScriptList;

	override function create():Void {
		FlxG.cameras.reset(camGame = new FlxCamera());
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		camGame.bgColor.alpha = 0;

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.gameVisibility / 100);

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor = 0x00;

		super.create();
		Conductor.stop();

		Assets.audio('music/Breakfast.ogg');
		Assets.audio('sfx/gameover-start.ogg');
		Assets.audio('sfx/gameover-loop.ogg');

		self = this;

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.gameVisibility <= 0) {
			FlxG.camera.visible = false;
			FlxG.camera.active = false;
			camHUD.bgColor = 0x00;
		}

		stats = {};

		events = new EventHandler();
		events.registerEvent("Retarget Camera", moveCamera);
		events.registerEvent("Zoom Camera", zoomCamera);
		events.registerEvent("Bump Interval", setZoomInterval);

		scripts = new ScriptList();
		scripts.loadFolder("scripts");
		scripts.loadFolder("songs/" + songID); // may become limited to only the addons list

		// TODO: make the strings customizible
		spectator = new Character(0, 0, 'gf');
		scripts.loadFile("characters/" + spectator.name); // these may be attached to the instance itself later on but
		enemy = new Character(0, 0, 'bf');
		scripts.loadFile("characters/" + enemy.name);
		player = new Character(0, 0, 'bf');
		scripts.loadFile("characters/" + player.name);
		add(stage = new Stage('stage'));
		scripts.loadFile("stages/" + stage.name);
		scripts.call("loadedStage");

		// don't want the positions auto instantiating/adding (it's a whole story trust me it's for the better)
		if (stage.hasSpectatorPos())
			stage.spectatorPos.add(spectator);
		if (stage.hasEnemyPos())
			stage.enemyPos.add(enemy);
		if (stage.hasPlayerPos())
			stage.playerPos.add(player);

		defaultZoom = stage.zoom;
		camFollow = new FlxObject(stage.cameraPos.x, stage.cameraPos.y, 2, 2);
		if (stage.canMoveCamera)
			moveCamera(0);
		FlxG.camera.follow(camFollow, LOCKON, 0.1); // turns out our flixel still scrolls to the target the ol fps dependant way wuh oh
		FlxG.camera.zoom = stage.zoom;
		FlxG.camera.snapToTarget();

		Conductor.metronome = Settings.data.metronome;

		noteSkin = Settings.data.noteSkin;
		downscroll = Settings.data.downscroll;

		var skin:Noteskin = Noteskin.get('images/noteSkins/' + noteSkin);
		var strumlineYPos:Float = downscroll ? FlxG.height - 50 - skin.spacing * Settings.data.strumSize : 50;

		leftStrumline = new Strumline(320, strumlineYPos, skin);
		rightStrumline = new Strumline(960, strumlineYPos, skin);

		add(notefield = new NoteField([leftStrumline, rightStrumline], playerID));
		notefield.cameras = [camHUD];
		notefield.noteHit = noteHit;
		notefield.noteMissed = noteMissed;
		notefield.sustainHit = sustainHit;
		notefield.sustainDropped = sustainDropped;
		notefield.assistTicks = Settings.data.assistTicks;
		notefield.scrollSpeed = Settings.data.scrollSpeed;
		notefield.scrollDirection = Settings.data.scrollDirection;
		notefield.underlays.alpha = Settings.data.laneUnderlay;

		if (Settings.data.centeredNotes) {
			for (i => strumline in notefield.strumlines.members) {
				if (i != playerID) strumline.visible = false;
				else strumline.screenCenter(X);
			}
		}

		add(hud = new FlxSpriteGroup());
		hud.cameras = [camHUD];

		add(judgeSprite = new JudgeDisplay(400, 300));
		judgeSprite.camera = camHUD;

		var judgeY:Float = judgeSprite.y + judgeSprite.height;
		add(comboSprite = new ComboDisplay(judgeSprite.x + 50, judgeY + 20));
		comboSprite.cameras = [camHUD];
		comboSprite.colorMode = switch (Settings.data.comboTinting) {
			case "Per-Note": PER_NOTE;
			case "Clear Flag": CLEAR_FLAG;
			default: NONE;
		};

		load();
		makeHUD();
		scripts.call("create");
	}

	function openPauseMenu() {
		final substate:PauseMenu = new PauseMenu(songID, Difficulty.current, 0);
		substate.cameras = [camOther];

		openSubState(substate);
	}

	override function update(delta:Float) {
		super.update(delta);
		events.update(Conductor.clock);

		updateCameraScale(delta);
		updateTimeText();
		updateIconScales(delta);
		updateIconPositions();

		if (FlxG.keys.justPressed.ENTER) {
			openPauseMenu();
		}

		scripts.call("update", [delta]);
	}

	override function destroy():Void {
		Judgement.resetHits();
		super.destroy();

		self = null;
	}

	override function beatHit(beat:Int):Void {
		// there may be an offset and hud bump softcoding later on but
		if (zoomInterval > 0 && beat % zoomInterval == 0) {
			FlxG.camera.zoom += zoomStrength;
			camHUD.zoom += zoomStrength * 2;
		}

		iconP1.scale.set(1, 1);
		iconP1.updateHitbox();

		iconP2.scale.set(1, 1);
		iconP2.updateHitbox();

		for (character in [player, enemy, spectator]) {
			if (!character.autoIdle || beat % character.danceInterval != 0) continue;
			character.dance();
		}

		scripts.call("beatHit", [beat]);
	}

	function load() {
		chart = Song.load('songs/$songID', Difficulty.current);
		stats.songName = chart.title;
		stats.difficulty = Difficulty.current;

		scripts.call("loadSong", [chart]);

		events.load(chart);
		notefield.load(chart, {
			scrollVelocities: Settings.data.gameplayModifiers['svs'],
			sustains: Settings.data.gameplayModifiers['sustains'],
			randomizedNotes: Settings.data.gameplayModifiers['randomizedNotes'],
			mirroredNotes: Settings.data.gameplayModifiers['mirroredNotes']
		});
		Conductor.clock.reset(chart);
		Conductor.clock.offset = chart.offset;

		Conductor.inst = FlxG.sound.load(Assets.audio('songs/$songID/Inst'));
		Conductor.inst.onComplete = function() songCompleted();

		stats.length = Conductor.inst.length;

		if (Assets.exists('songs/$songID/Vocals.ogg')) {
			Conductor.vocals = FlxG.sound.load(Assets.audio('songs/$songID/Vocals'));
		}

		// quickly plays the song and then stops it
		// so that when the song actually starts playing later
		// it doesn't stutter for a bit
		//
		// why does this actually work what the fuck
		var lastVolume:Float = Conductor.volume;
		Conductor.volume = 0; // to make sure we don't actually hear a sliver of the audio
		Conductor.inst.play();
		Conductor.inst.stop();

		if (Conductor.vocals != null) {
			Conductor.vocals.play();
			Conductor.vocals.stop();
		}

		Conductor.volume = lastVolume;

		// TODO: make this customizable
		Conductor.audioTime = -extraTime;
		Conductor.clock.active = true;
		new FlxTimer().start(extraTime / 1000, function(_) {
			Conductor.play();
			updateTime = true;
		});
	}

	function getCharacter(playerID:Int):Character {
		return switch playerID {
			default: null;

			case 0: enemy;
			case 1: player;
			case 2: spectator;
		}
	}
	
	var currentStat:Int = 0;
	function noteHit(strumline:Strumline, note:Note) {
		// havent added the script calls here because i'd to see if i can make this a bit customizible
		// like a HitBehavior sorta thing like cne and vslice

		getCharacter(note.player).sing('sing', Note.directions[note.lane]);

		if (note.player != notefield.playerID) return;

		var deviation:Float = note.getDeviation(notefield.input.timestamp);

		stats.registerNote({
			time: Std.int(note.time),
			deviation: deviation
		});

		var judgeID:Int = Judgement.getID(deviation);
		var judge:Judgement = Judgement.current[judgeID];
		judge.hits++;

		// TODO: make this not so hardcoded (hell even the skin is settings only)
		if (Settings.data.noteSplashSkin != "none" && judgeID <= 1) {
			var splash = NoteSplash.getSplash(note.receptor);
			splash.hit(note.receptor);
		}

		if (note.behavior.punishable || judge.breaksCombo) {
			stats.comboBreaks++;
			stats.combo = 0;
		} else {
			stats.notesHit++;
			stats.combo++;
		}

		health += judge.health;

		judgeSprite.display(deviation);
		comboSprite.display(stats.combo);

		scoring.noteHit(note, deviation);
		accuracy.noteHit(note, deviation);

		updateInfo();
		updateJudgeCounter();
		comboSprite.colorizeCombo(judge, stats.clearType);
	}

	function noteMissed(strumline:Strumline, note:Note) {
		stats.comboBreaks++;
		stats.misses++;
		stats.combo = 0;
		health -= 12.5;

		scoring.noteMissed(note);
		accuracy.noteMissed(note);

		updateInfo();
		updateJudgeCounter();

		player.sing('miss', Note.directions[note.lane]);
	}

	function sustainHit(strumline:Strumline, sustain:Sustain, mostRecent:Bool) {
		if (mostRecent) {
			getCharacter(sustain.player).sing('sing', Note.directions[sustain.lane]);
		}

		if (sustain.player != notefield.playerID) return;
		scoring.sustainHit(sustain);
		accuracy.sustainHit(sustain);

		updateInfo();
	}

	function sustainDropped(strumline:Strumline, sustain:Sustain) {
		stats.comboBreaks++;
		stats.combo = 0;

		scoring.sustainDropped(sustain);
		accuracy.sustainDropped(sustain);

		updateInfo();
		updateJudgeCounter();

		player.sing('miss', Note.directions[sustain.lane]);
	}

	var judgeNames:FlxText;
	var judgeCounters:FlxText;
	var clearTypeTxt:FlxText;
	var timeText:FlxText;
	var updateTime:Bool = false;
	var healthBar:Bar;
	var iconP1:CharIcon;
	var iconP2:CharIcon;
	function makeHUD() {
		if (hud == null) return;
		hud.clear();

		final isEnemy = Settings.data.gameplayModifiers['playingSide'] == 'Opponent';

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, function() return health, 0, 100));
		healthBar.setColors(enemy.healthColor, player.healthColor);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP1 = new CharIcon(player.icon, true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP1.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP2 = new CharIcon(enemy.icon));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		iconP2.alpha = Settings.data.healthBarAlpha;

		updateIconPositions();

		// fuck it im pulling a forever engine
		hud.add(timeText = new FlxText(0, downscroll ? 675 : 15, 500, '${chart.title} (Starting....)', 18));
		timeText.screenCenter(X);
		timeText.alignment = 'center';
		timeText.font = Assets.getPath('fonts/LineSeed.ttf');
		timeText.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeText.borderSize = 1.5;
		updateTimeText();
		timeText.visible = Settings.data.timeText;

		hud.add(infoText = new FlxText(0, downscroll ? 15 : 675, FlxG.width, '', 18));
		infoText.alignment = 'center';
		infoText.font = Assets.getPath('fonts/LineSeed.ttf');
		infoText.borderStyle = FlxTextBorderStyle.OUTLINE;
		infoText.borderSize = 1.5;

		hud.add(judgeNames = new FlxText(5, 0, 0, '', 18));
		judgeNames.font = Assets.getPath('fonts/LineSeed.ttf');
		judgeNames.color = 0xFFFF0000; // sets the default format color to the miss color
		judgeNames.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeNames.borderSize = 1.5;
		judgeNames.visible = Settings.data.judgementCounter;
		generateJudgeColors();
		judgeNames.screenCenter(Y);

		hud.add(judgeCounters = new FlxText((judgeNames.x + judgeNames.width) + 50, judgeNames.y, 75, '', judgeNames.size));
		judgeCounters.font = judgeNames.font;
		judgeCounters.alignment = 'right';
		judgeCounters.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeCounters.borderSize = 1.5;
		judgeCounters.wordWrap = false;
		judgeCounters.visible = Settings.data.judgementCounter;
		updateJudgeCounter();

		var clearTypePos = FlxPoint.get();
		if (Settings.data.judgementCounter) {
			clearTypePos.x = judgeNames.x + 45;
			clearTypePos.y = (judgeNames.y + judgeNames.height);
		} else {
			clearTypePos.x = isEnemy ? FlxG.width - 10 - judgeCounters.fieldWidth : 10;
			clearTypePos.y = FlxG.height - 30;
		}

		hud.add(clearTypeTxt = new FlxText(
			clearTypePos.x, 
			clearTypePos.y, 
			judgeCounters.fieldWidth, '', judgeNames.size
		));
		clearTypeTxt.font = judgeNames.font;
		clearTypeTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		clearTypeTxt.borderSize = 1.5;
		clearTypeTxt.alignment = Settings.data.judgementCounter ? 'center' : 'left';

		updateInfo();
		infoText.screenCenter(X);
	}

	public function generateJudgeColors() {
		if (!Settings.data.judgementCounter) return;

		judgeNames.clearFormats();
		judgeNames.text = "";
		var lastNameEnd:Int = 0;
		for (i in 0 ... Judgement.current.length) {
			final judge:Judgement = Judgement.current[i];

			var nameLength:Int = judge.name.length;
			var shortenedName:String = judge.name.charAt(0) + judge.name.charAt(nameLength - 1);

			judgeNames.text += shortenedName.toUpperCase() + "\n";
			judgeNames.addFormat(new FlxTextFormat(judge.color), lastNameEnd, judgeNames.text.length);
			lastNameEnd = judgeNames.text.length;
		}
		judgeNames.text += "MS";
		judgeNames.updateHitbox();
	}

	function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;

		judgeCounters.text = '';
		for (i in 0 ... Judgement.current.length) {
			var judge:Judgement = Judgement.current[i];
			judgeCounters.text += Util.moneyString(judge.hits) + '\n';
		}

		judgeCounters.text += Math.max(stats.misses, 0);
	}

	dynamic function updateTimeText() {
		if (!Settings.data.timeText || !updateTime) return;

		var current:String = flixel.util.FlxStringUtil.formatTime(Conductor.audioTime * 0.001, false);
		var duration:String = flixel.util.FlxStringUtil.formatTime(Conductor.inst.length * 0.001, false);

		timeText.text = '${chart.title} ($current / $duration)';
	}

	function death() {
		stats.time = Conductor.audioTime;
		Conductor.stop();

		for (camera in FlxG.cameras.list) camera.visible = false;
		camOther.visible = true;

		var menu = new FailedMenu(stats);
		menu.cameras = [camOther];
		openSubState(menu);
	}

	function updateInfo():Void {
		stats.clearType = stats.getClearType();

		if (stats.clearType != CLEAR) {
			clearTypeTxt.text = stats.clearType;
			clearTypeTxt.color = stats.clearType.color;
		} else clearTypeTxt.visible = false;

		stats.grade = stats.getGrade();
		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);

		infoText.text = 'Score: ${Util.moneyString(stats.score)}';

		if (stats.clearType != CLEAR) {
			infoText.text += ' | Combo Breaks: ${stats.comboBreaks}';
		}

		if (!Settings.data.hideAcc)
			infoText.text += ' | Accuracy: ${Util.truncateFloat(stats.accuracy, 3)}%';
	}

	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconStates() {
		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0;
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0;
	}

	dynamic function updateIconScales(delta:Float):Void {
		var mult:Float = FlxMath.lerp(0.8, iconP1.scale.x, Math.exp(-delta * 9));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(0.8, iconP2.scale.x, Math.exp(-delta * 9));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	function updateCameraScale(delta:Float):Void {
		if (!resetZoom) return;

		final scalingMult:Float = Math.exp(-delta * 6);
		camGame.zoom = FlxMath.lerp(defaultZoom, camGame.zoom, scalingMult);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, scalingMult);
	}

	@:unreflective
	function songCompleted() {
		endSong();
	}

	// forceLeave:Bool - forces you to leave to the main menu
	public function endSong(?forceLeave:Bool = false) {
		persistentUpdate = false;
		Conductor.stop();
		var results = new ResultsScreen(stats);
		results.cameras = [camOther];
		openSubState(results);
	}


	var camMoveTwn:FlxTween;
	public function moveCamera(target:Int, ?ease:String = "CLASSIC", ?duration:Float = 4, ?xOffset:Float = 0, ?yOffset:Float = 0, ?offset:Bool = false) {
		if (camMoveTwn != null)
			camMoveTwn.cancel();

		var char = getCharacter(target);
		if (char == null) {
			camFollow.setPosition(
				(offset ? camFollow.x : 0) + xOffset,
				(offset ? camFollow.y : 0) + yOffset
			);
		} else {
			var xMult = char.facingLeft != char.shouldFaceLeft ? -1 : 1;
			var midpoint = char.getMidpoint();
			midpoint.add(char.cameraOffset.x * xMult + xOffset, char.cameraOffset.y + yOffset);
	
			camFollow.setPosition(midpoint.x, midpoint.y);
			midpoint.put();
		}

		switch (ease) {
			case "CLASSIC":
				return;
			case "INSTANT":
				FlxG.camera.snapToTarget();
			default:
				var easeFunc = Util.easeFromString(ease);
				camMoveTwn = FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x, y: camFollow.y}, duration * Conductor.semiquaver * 0.001, {ease: easeFunc});
		}
	}
	
	var camZoomTwn:FlxTween;
	public function zoomCamera(zoom:Float, ?ease:String = "CLASSIC", ?duration:Float = 4, ?mode:String = "direct") {
		if (camZoomTwn != null)
			camZoomTwn.cancel();

		var targetZoom = mode.toLowerCase() == "direct" ? zoom : zoom * stage.zoom;

		defaultZoom = targetZoom;
		switch (ease) {
			case "CLASSIC":
				return;
			case "INSTANT":
				FlxG.camera.zoom = targetZoom;
			default:
				var easeFunc = Util.easeFromString(ease);
				camZoomTwn = FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration * Conductor.semiquaver * 0.001, {ease: easeFunc});
		}
	}

	public function setZoomInterval(interval:Int, strength:Float) {
		zoomInterval = interval;
		zoomStrength = 0.015 * strength;
	}
}