package funkin.states;

import funkin.states.PlayState.NoteHit;
import funkin.shaders.SwirlBGShader;

@:structInit @:publicFields class SongResult {
	var song:String;
	var score:Int;
	var accuracy:Float;
	var notesHit:Array<NoteHit>;
	var judges:Array<Judgement>;
	var songLength:Float;
}

@:structInit class PotentialMod {
	public var condition:Void->Bool;
	public var make:Void->String;
}

// ok so   uhhhhhhhhhhhhhh
// clone hero
// plus etterna
// with a mix of osu because you can scroll down on osu for more info
class ResultsScreen extends FunkinState {
	var modifiers:Array<PotentialMod> = [
		{
			condition: () -> Settings.data.gameplayModifiers["botplay"],
			make: () -> "BOTPLAY"
		},
		{
			condition: () -> Settings.data.gameplayModifiers["playingSide"] != "Default",
			make: () -> "Playing as " + Settings.data.gameplayModifiers["playingSide"]
		},
		{
			condition: () -> PlayState.song.meta.hasModchart && Settings.data.gameplayModifiers["modcharts"],
			make: () -> "Modcharted"
		},
		{
			condition: () -> Settings.data.gameplayModifiers["playbackRate"] != 1.0,
			make: () -> Settings.data.gameplayModifiers["playbackRate"] + "x SPEED"
		},
		{
			condition: () -> Settings.data.gameplayModifiers["minClearType"] != "Clear",
			make: () -> "Minimum Clear Type: " + Settings.data.gameplayModifiers["minClearType"]
		},
		{
			condition: () -> Settings.data.gameplayModifiers["noFail"],
			make: () -> "No Fail"
		},
		{
			condition: () -> Settings.data.gameplayModifiers["mirroredNotes"] && !Settings.data.gameplayModifiers["randomizedNotes"],
			make: () -> "Mirrored Notes"
		},
		{
			condition: () -> Settings.data.gameplayModifiers["randomizedNotes"],
			make: () -> "Randomized Notes"
		},
		{
			condition: () -> !Settings.data.gameplayModifiers["sustains"],
			make: () -> "No Holds"
		},
		{
			condition: () -> Settings.data.gameplayModifiers["blind"],
			make: () -> (FlxG.random.bool(10) ? "Rudy Rudy (Blind)" : "Blind")
		}
	];

	var weekFile:WeekFile;
	var wasStory:Bool = false;
	var difficulty:String;
	var data:Array<SongResult>;

	var colorPulse:Float = 0;
	var songColor:FlxColor = 0xFF808080;
	var swirlShader:SwirlBGShader;
	var bg:FunkinSprite;
	
	var timeBoxes:FlxTypedGroup<FunkinSprite>;
	var timeDots:FlxTypedGroup<FunkinSprite>;

	var scrollEmpty:FunkinSprite;
	var scrollFill:FunkinSprite;
	var scrollObj:FlxObject;
	var scrollMax:Float = 0;
	var scrollGrab:Null<Float> = null;
	var scrollGrabY:Float = 0;

	public function new(story:Bool, diff:String, inputData:Array<SongResult>) {
		super();
		wasStory = story;
		difficulty = diff;
		data = inputData;
	}

	override function create():Void {
		scrollObj = new FlxObject(640, 360, 2, 2);
		FlxG.camera.follow(scrollObj, LOCKON, 0.15);

		Conductor.inst = FlxAudioHandler.loadMusic(Paths.audioPath('results', 'music'), true);
		Conductor.offset = -0.050;
		Conductor.timingPoints = [{bpm: 140, beatsPerMeasure: 4}];
		Conductor.play();

		weekFile = WeekData.list[WeekData.current];
		for (song in weekFile.songs)
			songColor = (song.id == data[data.length - 1].song) ? song.color : songColor;

		var swirlBG = new FunkinSprite(0, 0, Paths.image("menus/results/fluid"));
		swirlBG.scrollFactor.set();
		swirlBG.screenCenter();
		swirlBG.shader = swirlShader = new SwirlBGShader();
		swirlBG.alpha = 0.5;
		var col1 = FlxColor.interpolate(0xFF000018, songColor, 0.5);
		var col2 = FlxColor.interpolate(0xFF000018, songColor, 0.25);
		swirlShader.redCol.value = [col1.redFloat, col1.greenFloat, col1.blueFloat];
		swirlShader.greenCol.value = [col2.redFloat, col2.greenFloat, col2.blueFloat];
		add(swirlBG);

		add(scrollEmpty = new FunkinSprite(FlxG.width - 15, 5));
		scrollEmpty.makeGraphic(1, 1, songColor);
		scrollEmpty.scale.set(10, FlxG.height - 10);
		scrollEmpty.updateHitbox();
		scrollEmpty.alpha = 0.35;
		scrollEmpty.scrollFactor.set();
		add(scrollFill = new FunkinSprite(FlxG.width - 15, 5));
		scrollFill.makeGraphic(1, 1, songColor);
		scrollFill.scale.set(10, FlxG.height - 10);
		scrollFill.origin.set();
		scrollFill.scrollFactor.set();

		// add(bg = new FunkinSprite(0, 0, Paths.image("menus/lineBG")));
		// bg.screenCenter();
		// bg.color = songColor;
		
		// offset.
		var clear:FlxText = new FlxText(20, 10, 0, (wasStory ? "Week" : "Song") + " Cleared!", 48);
		clear.font = Paths.font("LineSeed.ttf");
		clear.alpha = 0;
		add(clear);
		FlxTween.tween(clear, {alpha: 1, y: clear.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.1});

		var bars = new FlxTypedGroup<FunkinSprite>();
		add(bars);
		var texts = new FlxTypedGroup<FlxText>();
		add(texts);

		add(timeBoxes = new FlxTypedGroup<FunkinSprite>());
		add(timeDots = new FlxTypedGroup<FunkinSprite>());
		for (i => result in data) {
			var meta = Meta.load(result.song);

			var mean = 0.0;
			for (hit in result.notesHit)
				mean += Math.abs(hit.diff);
			mean /= result.notesHit.length;

			var song:FlxText = new FlxText(FlxG.width - 20, 15 + FlxG.height * i, 0, meta.songName, 32);
			song.font = Paths.font("vcr.ttf");
			song.x -= song.width;
			song.alpha = 0;
			add(song);
	
			var songDifficulty:FlxText = new FlxText(FlxG.width - 20, 15 + 32 + FlxG.height * i, 0, difficulty.toUpperCase(), 32);
			songDifficulty.font = Paths.font('vcr.ttf');
			songDifficulty.x -= songDifficulty.width;
			songDifficulty.alpha = 0;
			add(songDifficulty);
	
			var timeBox = new FunkinSprite(440, 180 + FlxG.height * i - 5);
			timeBox.makeGraphic(820, 500, 0x80000000);
			timeBox.alpha = 0;
			timeBoxes.add(timeBox);
			timeBox.graphic.bitmap.fillRect(new openfl.geom.Rectangle(0, timeBox.graphic.height * 0.5 - 1, timeBox.graphic.width, 2), 0xFFFFFFFF);

			var score = new FlxText(timeBox.x + 10, timeBox.y, 0, 'Score: ' + Util.moneyString(result.score));
			score.setFormat(Paths.font("LineSeed.ttf"), 32, 0xFFFFFFFF, LEFT);
			score.y -= score.height;
			score.alpha = 0;
			add(score);
			var acc = new FlxText(timeBox.x + timeBox.width - 10, timeBox.y, 0, Util.truncateFloat(result.accuracy, 5) + "%");
			acc.setFormat(Paths.font("LineSeed.ttf"), 32, 0xFFFFFFFF, RIGHT);
			acc.x -= acc.width;
			acc.y -= acc.height;
			acc.alpha = 0;
			add(acc);

			var barBox = new FunkinSprite(20, timeBox.y + timeBox.height * 0.5 + 5);
			barBox.makeGraphic(1, 1, 0xFFFFFFFF);
			barBox.color = 0xFF000000;
			barBox.alpha = 0.5;
			bars.add(barBox); // let it dream

			var txt = new FlxText(barBox.x + 10, 0, 380, 'MA: ${Util.truncateFloat(result.judges[0].hits / result.judges[1].hits, 2)} | Mean: ${Util.truncateFloat(mean,  2)} ms');
			txt.setFormat(Paths.font("LineSeed.ttf"), 20, 0xFFFFFFFF, LEFT);
			texts.add(txt);
			
			barBox.scale.set(txt.fieldWidth + 20, 50 * result.judges.length + 5 + txt.height);
			barBox.updateHitbox();
			barBox.y -= barBox.height * 0.5;
			barBox.scale.x = 0;
			barBox.origin.set();
			barBox.offset.set();
			txt.y = barBox.y + barBox.height - txt.height;

			var barCount = 0;
			inline function makeJudgeBar(name:String, color:FlxColor, count:Int) {
				var empty = new FunkinSprite(barBox.x + 10, barBox.y + 10 + 50 * barCount);
				empty.makeGraphic(1, 1, 0xFFFFFFFF);
				empty.color = FlxColor.interpolate(color, 0xFF000018, 0.5);
				empty.scale.set(barBox.width - 20, 35);
				empty.updateHitbox();
				empty.scale.x = 0;
				empty.origin.set();
				empty.offset.set();
				bars.add(empty);

				var fill = new FunkinSprite(empty.x, empty.y);
				fill.makeGraphic(1, 1, 0xFFFFFFFF);
				fill.color = color;
				fill.scale.set(empty.width * (count / result.notesHit.length), empty.height);
				fill.updateHitbox();
				fill.scale.x = 0;
				fill.origin.set();
				fill.offset.set();
				bars.add(fill);

				var title = new FlxText(empty.x + 10, empty.y + empty.height * 0.5, 0, name);
				title.setFormat(Paths.font("LineSeedB.ttf"), 24, fill.color, LEFT, OUTLINE, empty.color);
				title.borderSize = 2;
				title.y -= title.height * 0.5;
				texts.add(title);

				var count = new FlxText(empty.x + empty.width - 10, empty.y + empty.height * 0.5, 0, Std.string(count));
				count.setFormat(Paths.font("LineSeed.ttf"), 24, fill.color, RIGHT, OUTLINE, empty.color);
				count.borderSize = 2;
				count.x -= count.width;
				count.y -= count.height * 0.5;
				texts.add(count);

				++barCount;
			}

			for (judge in result.judges)
				makeJudgeBar(judge.name.charAt(0).toUpperCase() + judge.name.substr(1), judge.color, judge.hits);

			FlxTween.tween(song, {alpha: 1, y: song.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(songDifficulty, {alpha: 1, y: songDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
			FlxTween.tween(timeBox, {alpha: 1, y: timeBox.y + 5}, 0.4, {ease: FlxEase.cubeOut, startDelay: 0.7});
			FlxTween.tween(score, {alpha: 1, y: score.y + 5}, 0.4, {ease: FlxEase.cubeOut, startDelay: 0.8});
			FlxTween.tween(acc, {alpha: 1, y: acc.y + 5}, 0.4, {ease: FlxEase.cubeOut, startDelay: 0.9});
		}
		FlxTween.num(0, 1, 0.5, {ease: FlxEase.cubeOut, startDelay: 0.9}, function(num) {
			for (bar in bars.members)
				bar.scale.x = bar.width * num;
			for (txt in texts.members)
				Util.clipByCoords(txt, null, bars.members[0].x + bars.members[0].scale.x, null, null);
		});

		scrollMax = FlxG.height * data.length + 360;
		var modsStr = "Active Mods:";
		for (mod in modifiers) {
			if (mod.condition())
				modsStr += "\n" + mod.make();
		}
		if (modsStr != "Active Mods:") {
			var modsTxt = new FlxText(FlxG.width - 20, 15 + FlxG.height * data.length, 0, modsStr);
			modsTxt.setFormat(Paths.font("LineSeed.ttf"), 32, 0xFFFFFFFF, RIGHT);
			modsTxt.x -= modsTxt.width;
			add(modsTxt);

			scrollMax += Math.max(modsTxt.height - (FlxG.height - 10), 0);
		} else
			scrollMax -= FlxG.height;

		scrollEmpty.visible = scrollFill.visible = scrollMax > 360;

		var timeDot = Paths.image("menus/results/noteHitDot", "images", false); // need gpu cache off cuz imma be fucking with bitmaps a bit
		var missLine = FlxG.bitmap.create(timeDot.width, Std.int(timeBoxes.members[0].height), 0xFF808080);
		missLine.destroyOnNoUse = false;

		var idx:Array<Int> = [for (res in data) 0];
		FlxTween.num(0, 1, 1.5, {startDelay: 0.8, ease: FlxEase.cubeOut}, function(num) {
			for (i => result in data) {
				final highestTiming = result.judges[result.judges.length - 1].timing;
				while (idx[i] < result.notesHit.length && num * result.songLength >= result.notesHit[idx[i]].time) {
					final hit = result.notesHit[idx[i]];
					final xPercent = hit.time / result.songLength;
					final yPercent = 1 - (hit.diff + highestTiming) / (highestTiming * 2);

					final dot = timeDots.recycle(FunkinSprite);
					dot.loadGraphic(hit.judge == "miss" ? missLine : timeDot);
					dot.setPosition(timeBoxes.members[i].x + (timeBoxes.members[i].width - dot.width) * xPercent, timeBoxes.members[i].y + (timeBoxes.members[i].height - dot.height) * yPercent);
					dot.offset.x = 20;
					dot.alpha = 0;
					dot.color = hit.color;
					dot.ID = i;
					++idx[i];
				}
			}
		});

	}

	override function update(delta:Float) {
		super.update(delta);

		colorPulse += delta;
		swirlShader.iTime.value[0] = colorPulse;
		//bg.color = FlxColor.interpolate(0xFF000018, songColor, (Math.cos(colorPulse) * 0.125 + 0.375));

		if (scrollMax > 360) {
			final downPressed = Controls.pressed("ui_down");
			if (FlxG.mouse.wheel != 0)
				scrollObj.y -= FlxG.mouse.wheel * 75;
			if (Controls.pressed("ui_up") || downPressed)
				scrollObj.y += delta * (downPressed ? 750 : -750);
			
			if (scrollObj.y < 360 || scrollObj.y > scrollMax)
				scrollObj.y = FlxMath.lerp(scrollObj.y, scrollObj.y < 360 ? 360 : scrollMax, delta * 10);
	
			if (FlxG.mouse.justPressed && FlxG.mouse.screenX >= scrollEmpty.x && FlxG.mouse.screenY >= scrollFill.y && FlxG.mouse.screenY <= scrollFill.y + scrollFill.scale.y) {
				scrollGrab = FlxG.mouse.screenY;
				scrollGrabY = FlxG.camera.scroll.y + 360;
			} else if (FlxG.mouse.justReleased)
				scrollGrab = null;
			if (scrollGrab != null)
				scrollObj.y = scrollGrabY + (FlxG.mouse.screenY - scrollGrab) * 2 / scrollEmpty.height * scrollMax;

			final overflow = (FlxG.camera.scroll.y < 0) ? -FlxG.camera.scroll.y : (FlxG.camera.scroll.y > scrollMax - 360) ? FlxG.camera.scroll.y - (scrollMax - 360) : 0;
			scrollFill.scale.y = (FlxG.height - overflow) / scrollMax * scrollEmpty.height;
			scrollFill.y = scrollEmpty.y + (scrollEmpty.height - scrollFill.scale.y) * Math.min(Math.max(FlxG.camera.scroll.y / (scrollMax - 360), 0), 1);
		}

		if (Controls.justPressed("back") || Controls.justPressed("accept")) {
			Conductor.stop();
			Conductor.reset();
			Util.toMenu(new FreeplayState());
			Paths.clearUnusedMemory();
		}

		for (dot in timeDots.members) {
			if (!dot.alive) continue;
			
			dot.alpha = FlxMath.lerp(dot.alpha, 1, delta * 5);
			dot.offset.x = 20 * (1.0 - dot.alpha);
			if (dot.alpha > 0.99) {
				final timeSpr = timeBoxes.members[dot.ID];
				timeSpr.stamp(dot, Math.round(dot.x - timeSpr.x), Math.round(dot.y - timeSpr.y));
				dot.kill();
			}
		}
	}
}