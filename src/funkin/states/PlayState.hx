package funkin.states;

import nevermore.core.Chart;
import nevermore.play.*;
import nevermore.play.note.*;
import nevermore.skins.Noteskin;

import funkin.core.scoring.*;
import funkin.core.accuracy.*;
import funkin.objects.JudgementSpr;
import funkin.objects.ComboNums;

class PlayState extends FunkinState {
	public static var songID:String = '';
	var chart:Chart;

	var notefield:NoteField;
	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	var noteSkin:String = 'funkin';
	var extraTime:Float = 2500; // 2.5 seconds
	var downscroll:Bool = false;

	var stats:Statistics = {};
	var scoring:ScoreHandler = new DefaultScoring();
	var accuracy:AccuracyHandler = new DefaultAccuracy();

	var hud:FlxSpriteGroup;
	var infoText:FlxText;
	var judgeSprite:JudgementSpr;
	var comboSprite:ComboNums;

	override function create():Void {
		super.create();
		Conductor.stop();

		Conductor.metronome = Settings.data.metronome;

		noteSkin = Settings.data.noteSkin;
		downscroll = Settings.data.downscroll;

		var skin:Noteskin = Noteskin.get('images/noteSkins/' + noteSkin);
		var strumlineYPos:Float = downscroll ? FlxG.height - 50 - skin.spacing * Settings.data.strumSize : 50;

		leftStrumline = new Strumline(320, strumlineYPos, skin);
		rightStrumline = new Strumline(960, strumlineYPos, skin);

		add(notefield = new NoteField([leftStrumline, rightStrumline], 1));
		notefield.noteHit = noteHit;
		notefield.noteMissed = noteMissed;
		notefield.sustainHit = sustainHit;
		notefield.sustainDropped = sustainDropped;
		notefield.assistTicks = Settings.data.assistTicks;
		notefield.scrollSpeed = Settings.data.scrollSpeed;

		add(hud = new FlxSpriteGroup());
		add(judgeSprite = new JudgementSpr(400, 300));

		var judgeY:Float = judgeSprite.y + judgeSprite.height;
		add(comboSprite = new ComboNums(judgeSprite.x + 50, judgeY + 20));

		load();
		makeHUD();
	}

	function load() {
		chart = Song.load('songs/$songID', Difficulty.current);

		notefield.load(chart, {
			scrollVelocities: Settings.data.gameplayModifiers['svs'],
			sustains: Settings.data.gameplayModifiers['sustains'],
			randomizedNotes: Settings.data.gameplayModifiers['randomizedNotes'],
			mirroredNotes: Settings.data.gameplayModifiers['mirroredNotes']
		});
		Conductor.clock.reset(chart.timingPoints);
		Conductor.clock.offset = chart.offset;

		Conductor.inst = FlxG.sound.load(Assets.audio('songs/$songID/Inst'));
		Conductor.inst.onComplete = function() songCompleted();

		if (Assets.exists('songs/$songID/Vocals.ogg')) {
			Conductor.vocals = FlxG.sound.load(Assets.audio('songs/$songID/Vocals'));
		}

		Conductor.audioTime = -extraTime;
		Conductor.clock.active = true;
		new FlxTimer().start(extraTime / 1000, function(_) {
			Conductor.play();
		});
	}

	function noteHit(strumline:Strumline, note:Note) {
		if (note.player != notefield.playerID) return;

		stats.notesHit++;
		stats.combo++;

		var deviation:Float = note.getDeviation(notefield.input.timestamp);

		judgeSprite.display(deviation);
		comboSprite.display(stats.combo);

		scoring.noteHit(note, deviation);
		accuracy.noteHit(note, deviation);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
	}

	function noteMissed(strumline:Strumline, note:Note) {
		stats.comboBreaks++;
		stats.combo = 0;

		scoring.noteMissed(note);
		accuracy.noteMissed(note);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
	}

	function sustainHit(strumline:Strumline, sustain:Sustain, mostRecent:Bool) {
		if (sustain.player != notefield.playerID) return;
		scoring.sustainHit(sustain);
		accuracy.sustainHit(sustain);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
	}

	function sustainDropped(strumline:Strumline, sustain:Sustain) {
		scoring.sustainDropped(sustain);
		accuracy.sustainDropped(sustain);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
	}

	function makeHUD() {
		if (hud == null) return;
		hud.clear();

		final isEnemy = Settings.data.gameplayModifiers['playingSide'] == 'Opponent';

/*		hud.add(hitErrorBar = new HitErrorBar(isEnemy ? 20 : FlxG.width - 25, 0));
		hitErrorBar.screenCenter(Y);
		hitErrorBar.visible = Settings.data.hitErrorBar;

		hud.add(timingIndicator = new FlxText((hitErrorBar.x + (isEnemy ? 25 : -25)) - 150, 0, 300, '0 ms', 16));
		timingIndicator.alignment = 'center';
		timingIndicator.alpha = 0;
		timingIndicator.font = Assets.getPath('fonts/LineSeed.ttf');
		timingIndicator.borderSize = 1.25;
		timingIndicator.borderStyle = OUTLINE;
		timingIndicator.borderColor = 0xFF000000;
		timingIndicator.angle = isEnemy ? -90 : 90;
		timingIndicator.screenCenter(Y);

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, function() return health, 0, 100));
		healthBar.setColors(dad.healthColor, bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP1 = new CharIcon(bf.icon, true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP1.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP2 = new CharIcon(dad.icon));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		iconP2.alpha = Settings.data.healthBarAlpha;

		updateIconPositions();

		// fuck it im pulling a forever engine
		hud.add(timeText = new FlxText(0, downscroll ? 675 : 15, 500, '$songName (Starting....)', 18));
		timeText.screenCenter(X);
		timeText.alignment = 'center';
		timeText.font = Assets.getPath('fonts/LineSeed.ttf');
		timeText.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeText.borderSize = 1.5;
		updateTimeText();
		timeText.visible = Settings.data.timeText;*/

		hud.add(infoText = new FlxText(0, downscroll ? 15 : 675, FlxG.width, '', 18));
		infoText.alignment = 'center';
		infoText.font = Assets.getPath('fonts/LineSeed.ttf');
		infoText.borderStyle = FlxTextBorderStyle.OUTLINE;
		infoText.borderSize = 1.5;

/*		hud.add(judgeNames = new FlxText(5, 0, 0, '', 18));
		judgeNames.font = Assets.getPath('fonts/LineSeed.ttf');
		judgeNames.color = 0xFF999999; // sets the default format color to the miss color
		judgeNames.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeNames.borderSize = 1.5;
		judgeNames.visible = Settings.data.judgementCounter;
		generateJudgeColors();
		judgeNames.screenCenter(Y);
		if (isEnemy)
			judgeNames.x = FlxG.width - ((judgeNames.x + judgeNames.width) + 50) - 75;

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

		hud.add(clearType = new FlxText(
			clearTypePos.x, 
			clearTypePos.y, 
			judgeCounters.fieldWidth, '', judgeNames.size
		));
		clearType.font = judgeNames.font;
		clearType.borderStyle = FlxTextBorderStyle.OUTLINE;
		clearType.borderSize = 1.5;
		clearType.alignment = Settings.data.judgementCounter ? 'center' : 'left';

		hud.add(botplayTxt = new FunkinSprite(0, 0, Assets.image('images/ui/botplay')));
		botplayTxt.visible = false;
		botplayTxt.screenCenter();
		botplayTxt.camera = camHUD;*/

		updateInfo();
		infoText.screenCenter(X);
	}

/*	public function generateJudgeColors() {
		if (!Settings.data.judgementCounter) return;

		judgeNames.clearFormats();
		judgeNames.text = "";
		var lastNameEnd = 0;
		for (i in 0...Judgement.current.length) {
			final judge = Judgement.current[i];

			judgeNames.text += judge.name + "\n";
			judgeNames.addFormat(new FlxTextFormat(/judge.color/ 0xFFFFFFFF), lastNameEnd, judgeNames.text.length);
			lastNameEnd = judgeNames.text.length;
		}
		judgeNames.text += "MS";
		judgeNames.updateHitbox();
	}

	function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;

		judgeCounters.text = '';
		var judgeBreaks:Int = 0;
		for (i in 0...Judgement.current.length) {
			var judge = Judgement.current[i];
			judgeCounters.text += Util.moneyString(judge.hits) + '\n';
			if (judge.causesMisses) judgeBreaks += judge.hits;
		}

		judgeCounters.text += Math.max(comboBreaks - judgeBreaks, 0);
	}*/

	function updateInfo():Void {
		infoText.text = 'Score: ${Util.moneyString(stats.score)} | Combo Breaks: ${stats.comboBreaks}';
		if (!Settings.data.hideAcc)
			infoText.text += ' | Accuracy: ${Util.truncateFloat(stats.accuracy, 3)}%';
	}

	@:unreflective
	function songCompleted() {
		//if (disqualified) {endSong(); return;}

/*		var modifiers = Settings.data.gameplayModifiers.copy();
		#if !SV_ALLOWED
		modifiers["svs"] = false;
		#end

		Scores.setPlay({
			songID: songID,
			difficulty: Difficulty.current,

			score: score,
			accuracy: accuracy,

			modifiers: modifiers.copy()
		});

		if (storyMode) {
			storyScore += score;
			if (currentLevel == songList.length - 1) {
				Scores.setWeekPlay({
					weekID: weekData.fileName,
					difficulty: Difficulty.current,
					score: storyScore,
					modifiers: modifiers.copy()
				});
				weekData = null;
				storyScore = 0;
		}
		}*/

		endSong();
		//Scores.save();
	}

	// forceLeave:Bool - forces you to leave to the main menu
	public function endSong(?forceLeave:Bool = false) {
		/*if (!forceLeave && ScriptHandler.call('onEndSong', [songID], true) == -1) return;*/

		Conductor.stop();
		FlxG.switchState(new FreeplayState());
	}
}