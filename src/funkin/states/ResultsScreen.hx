package funkin.states;

import funkin.states.PlayState.NoteHit;

// ok so   uhhhhhhhhhhhhhh
// clone hero
// plus etterna
// with a mix of osu because you can scroll down on osu for more info
class ResultsScreen extends FunkinState {
	var weekFile:WeekFile;
	var wasStory:Bool = false;
	var difficulty:String;
	var songsPlayed:Array<String>;
	var notesHit:Array<Array<NoteHit>>;
	var judges:Array<Array<Judgement>>;
	var songLengths:Array<Float>;

	var colorPulse:Float = 0;
	var songColor:FlxColor = 0xFF808080;
	var bg:FunkinSprite;
	
	var timeBoxes:FlxTypedGroup<FunkinSprite>;
	var timeDots:FlxTypedGroup<FunkinSprite>;

	public function new(story:Bool, diff:String, songs:Array<String>, hits:Array<Array<NoteHit>>, judgeList:Array<Array<Judgement>>, lengths:Array<Float>) {
		super();
		wasStory = story;
		difficulty = diff;
		songsPlayed = songs;
		notesHit = hits;
		judges = judgeList;
		songLengths = lengths;
	}

	override function create():Void {
		Conductor.inst = FlxAudioHandler.loadMusic(Paths.audioPath('results', 'music'), true);
		Conductor.offset = -0.050;
		Conductor.timingPoints = [{bpm: 140, beatsPerMeasure: 4}];
		Conductor.play();

		weekFile = WeekData.list[WeekData.current];
		for (song in weekFile.songs)
			songColor = (song.id == songsPlayed[songsPlayed.length - 1]) ? song.color : songColor;

		add(bg = new FunkinSprite(0, 0, Paths.image("menus/lineBG")));
		bg.screenCenter();
		bg.color = songColor;
		
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
		for (i => song in songsPlayed) {
			var meta = Meta.load(song);
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
	
			inline function makeJudgeBar(name:String, color:FlxColor, count:Int) {
				var empty = new FunkinSprite(20, 150 + 50 * (bars.length * 0.5) + FlxG.height * i);
				empty.makeGraphic(1, 1, 0xFFFFFFFF);
				empty.color = FlxColor.interpolate(color, 0xFF000018, 0.5);
				empty.scale.set(400, 35);
				empty.updateHitbox();
				empty.scale.x = 0;
				empty.origin.set();
				empty.offset.set();
				bars.add(empty);

				var fill = new FunkinSprite(empty.x, empty.y);
				fill.makeGraphic(1, 1, 0xFFFFFFFF);
				fill.color = color;
				fill.scale.set(empty.width * (count / notesHit[i].length), empty.height);
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
			}

			for (judge in judges[i])
				makeJudgeBar(judge.name.charAt(0).toUpperCase() + judge.name.substr(1), judge.color, judge.hits);

			var timeBox = new FunkinSprite(440, 150 + FlxG.height * i - 5);
			timeBox.makeGraphic(820, 500, 0x80000000);
			timeBox.alpha = 0;
			timeBoxes.add(timeBox);
			timeBox.graphic.bitmap.fillRect(new openfl.geom.Rectangle(0, timeBox.graphic.height * 0.5 - 1, timeBox.graphic.width, 2), 0xFFFFFFFF);

			FlxTween.tween(song, {alpha: 1, y: song.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(songDifficulty, {alpha: 1, y: songDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
			FlxTween.tween(timeBox, {alpha: 1, y: timeBox.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
		}
		FlxTween.num(0, 1, 0.5, {ease: FlxEase.cubeOut, startDelay: 0.9}, function(num) {
			for (bar in bars.members)
				bar.scale.x = bar.width * num;
			for (txt in texts.members)
				Util.clipByCoords(txt, null, bars.members[0].x + bars.members[0].scale.x, null, null);
		});

		var timeDot = Paths.image("menus/noteHitDot", "images", false); // need gpu cache off cuz imma be fucking with bitmaps a bit
		var missLine = FlxG.bitmap.create(timeDot.width, Std.int(timeBoxes.members[0].height), 0xFF808080);
		missLine.destroyOnNoUse = false;

		var idx:Array<Int> = [for (hit in notesHit) 0];
		FlxTween.num(0, 1, 1.5, {startDelay: 0.8, ease: FlxEase.cubeOut}, function(num) {
			for (i => hits in notesHit) {
				final highestTiming = judges[i][judges[i].length - 1].timing;
				while (idx[i] < hits.length && num * songLengths[i] >= hits[idx[i]].time) {
					final hit = hits[idx[i]];
					final xPercent = hit.time / songLengths[i];
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
		bg.color = FlxColor.interpolate(0xFF000018, songColor, (Math.cos(colorPulse) * 0.125 + 0.375));

		if (Controls.justPressed("back") || Controls.justPressed("accept")) {
			Conductor.stop();
			Conductor.reset();
			Conductor.inst = FlxAudioHandler.loadMusic(Paths.audioPath('freakyMenu', 'music'), true);
			Conductor.timingPoints = [{bpm: 102, beatsPerMeasure: 4}];
			Conductor.play();
			Addons.current = '';
			Paths.clearUnusedMemory();
			FunkinState.switchState(new FreeplayState());
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