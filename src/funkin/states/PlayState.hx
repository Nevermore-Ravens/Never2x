package funkin.states;

import nevermore.core.Chart;
import nevermore.play.*;
import nevermore.play.note.*;
import nevermore.skins.Noteskin;

import funkin.core.scoring.*;
import funkin.core.accuracy.*;
import funkin.core.Statistics;
import funkin.objects.JudgeDisplay;
import funkin.objects.ComboDisplay;
import funkin.objects.Bar;
import funkin.objects.CharIcon;

class PlayState extends FunkinState {
	public static var songID:String = '';
	var chart:Chart;

	var notefield:NoteField;
	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	var noteSkin:String = 'funkin';
	var extraTime:Float = 2500; // 2.5 seconds
	var downscroll:Bool = false;

	var health:Float = 50;
	var iconSpacing:Float = 20;

	var stats:Statistics;
	var scoring:ScoreHandler = new DefaultScoring();
	var accuracy:AccuracyHandler = new DefaultAccuracy();

	var hud:FlxSpriteGroup;
	var infoText:FlxText;
	var judgeSprite:JudgeDisplay;
	var comboSprite:ComboDisplay;

	override function create():Void {
		super.create();
		Conductor.stop();

		stats = {};
		stats.judgements = Judgement.current;

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
		add(judgeSprite = new JudgeDisplay(400, 300));

		var judgeY:Float = judgeSprite.y + judgeSprite.height;
		add(comboSprite = new ComboDisplay(judgeSprite.x + 50, judgeY + 20));

		load();
		makeHUD();
	}

	override function update(delta:Float) {
		super.update(delta);

		updateTimeText();
		updateIconScales(delta);
		updateIconPositions();
	}

	override function destroy():Void {
		Judgement.resetHits();
		super.destroy();
	}

	override function beatHit(beat:Int):Void {
		iconP1.scale.set(1, 1);
		iconP1.updateHitbox();

		iconP2.scale.set(1, 1);
		iconP2.updateHitbox();
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
			updateTime = true;
		});
	}

	function noteHit(strumline:Strumline, note:Note) {
		if (note.player != notefield.playerID) return;

		stats.notesHit++;
		stats.combo++;

		var deviation:Float = note.getDeviation(notefield.input.timestamp);
		var judge:Judgement = Judgement.get(deviation);
		judge.hits++;

		if (judge.breaksCombo) {
			stats.comboBreaks++;
			stats.combo = 0;
		}

		judgeSprite.display(deviation);
		comboSprite.display(stats.combo);

		scoring.noteHit(note, deviation);
		accuracy.noteHit(note, deviation);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
		updateJudgeCounter();
	}

	function noteMissed(strumline:Strumline, note:Note) {
		stats.comboBreaks++;
		stats.combo = 0;

		scoring.noteMissed(note);
		accuracy.noteMissed(note);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
		updateJudgeCounter();
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
		stats.comboBreaks++;
		stats.combo = 0;

		scoring.sustainDropped(sustain);
		accuracy.sustainDropped(sustain);

		stats.score = scoring.get(stats);
		stats.accuracy = accuracy.get(stats);
		updateInfo();
		updateJudgeCounter();
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
		timingIndicator.screenCenter(Y);*/

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, function() return health, 0, 100));
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP1 = new CharIcon('bf', true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP1.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP2 = new CharIcon('dad'));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		iconP2.alpha = Settings.data.healthBarAlpha;

		updateIconPositions();

		// fuck it im pulling a forever engine
		hud.add(timeText = new FlxText(0, downscroll ? 675 : 15, 500, '$songID (Starting....)', 18));
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
		judgeNames.color = 0xFF999999; // sets the default format color to the miss color
		judgeNames.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeNames.borderSize = 1.5;
		judgeNames.visible = Settings.data.judgementCounter;
		generateJudgeColors();
		judgeNames.screenCenter(Y);
/*		if (isEnemy)
			judgeNames.x = FlxG.width - ((judgeNames.x + judgeNames.width) + 50) - 75;*/

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

		/*hud.add(botplayTxt = new FunkinSprite(0, 0, Assets.image('images/ui/botplay')));
		botplayTxt.visible = false;
		botplayTxt.screenCenter();
		botplayTxt.camera = camHUD;*/

		updateInfo();
		infoText.screenCenter(X);
	}

	public function generateJudgeColors() {
		if (!Settings.data.judgementCounter) return;

		judgeNames.clearFormats();
		judgeNames.text = "";
		var lastNameEnd:Int = 0;
		for (i in 0 ... Judgement.current.length) {
			final judge = Judgement.current[i];

			judgeNames.text += judge.name + "\n";
			judgeNames.addFormat(new FlxTextFormat(judge.color), lastNameEnd, judgeNames.text.length);
			lastNameEnd = judgeNames.text.length;
		}
		judgeNames.text += "MS";
		judgeNames.updateHitbox();
	}

	function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;

		judgeCounters.text = '';
		var judgeBreaks:Int = 0;
		for (i in 0 ... Judgement.current.length) {
			var judge:Judgement = Judgement.current[i];
			judgeCounters.text += Util.moneyString(judge.hits) + '\n';
			if (judge.breaksCombo) judgeBreaks += judge.hits;
		}

		judgeCounters.text += Math.max(stats.comboBreaks - judgeBreaks, 0);
	}

	dynamic function updateTimeText() {
		if (!Settings.data.timeText || !updateTime) return;

		var current:String = flixel.util.FlxStringUtil.formatTime(Conductor.audioTime * 0.001, false);
		var duration:String = flixel.util.FlxStringUtil.formatTime(Conductor.inst.length * 0.001, false);

		timeText.text = '$songID ($current / $duration)';
	}

	function updateInfo():Void {
		stats.clearType = stats.getClearType();
		stats.grade = stats.getGrade();

		infoText.text = 'Score: ${Util.moneyString(stats.score)}';

		if (stats.clearType != CLEAR) {
			infoText.text += ' | Combo Breaks: ${stats.comboBreaks}';
		}

		if (!Settings.data.hideAcc)
			infoText.text += ' | Accuracy: ${Util.truncateFloat(stats.accuracy, 3)}%';
		
		if (stats.clearType != CLEAR) {
			clearTypeTxt.text = stats.clearType;
			clearTypeTxt.color = stats.clearType.color;
		} else clearTypeTxt.visible = false;
	}

	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconStates() {
		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	}

	dynamic function updateIconScales(delta:Float):Void {
		var mult:Float = FlxMath.lerp(0.8, iconP1.scale.x, Math.exp(-delta * 9));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(0.8, iconP2.scale.x, Math.exp(-delta * 9));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
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