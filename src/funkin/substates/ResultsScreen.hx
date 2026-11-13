package funkin.substates;

import openfl.geom.Rectangle;
import funkin.core.N2XStatistics;
import funkin.objects.SkewedText;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.text.FlxText;

class ResultsScreen extends flixel.FlxSubState {
	var tweens:FlxTweenManager;
	var stats:N2XStatistics;

	var hitWindow:Float;
	var graphBG:FunkinSprite;
	var graphDots:FlxTypedGroup<FunkinSprite>;
	var lateTxt:FlxText;
	var earlyTxt:FlxText;

	var timeDot:FlxGraphic;
	var missLine:FlxGraphic;

	var meanLine:FunkinSprite;
	var meanTxt:FlxText;
	var stddLine:FunkinSprite;
	var stddTxt:FlxText;

	var bars:FlxTypedGroup<FlxSprite>;
	var barTxt:FlxTypedGroup<FlxText>;

	var scoreTxt:FlxText;
	var accuracyTxt:FlxText;
	var notes:FlxText;

	var tick:FlxSound;
	var title:SkewedText;
	var diff:SkewedText;
	// var credits:FlxText;

	var clearTxt:SkewedText;
	var rankTxt:SkewedText;

	var music:FlxSound;
	var exiting:Bool = false;

	public function new(stats:N2XStatistics) {
		super();
		this.stats = stats;
		hitWindow = stats.judgements[stats.judgements.length - 1].window;
	}

	override function create():Void {
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;
		add(bg);

		graphBG = new FunkinSprite(10, 10);
		graphBG.makeGraphic(FlxG.width - 20, 360, 0x80000000);
		add(graphBG);
		
		var fillRect = new Rectangle(0, Math.floor(graphBG.frameHeight * 0.5) - 1, graphBG.frameWidth, 2);
		graphBG.pixels.fillRect(fillRect, 0xFFFFFFFF);
		fillRect.height = 1;
		for (i in 0...(stats.judgements.length - 1)) {
			var color:FlxColor = FlxColor.interpolate(0xFF000000, stats.judgements[i].color, 0.5);
			color.alphaFloat = 0.5;

			var y = (graphBG.frameHeight * 0.5) * (stats.judgements[i].window / hitWindow);
			fillRect.y = Math.floor(graphBG.frameHeight * 0.5 - y);
			graphBG.pixels.fillRect(fillRect, color);

			fillRect.y = Math.floor(graphBG.frameHeight * 0.5 + y);
			graphBG.pixels.fillRect(fillRect, color);
		}

		add(graphDots = new FlxTypedGroup());

		meanLine = new FunkinSprite(graphBG.x, getGraphY(stats.mean, 3));
		meanLine.makeGraphic(1, 1, 0xC07984A1);
		meanLine.scale.set(graphBG.width, 3);
		meanLine.updateHitbox();
		add(meanLine);
		meanTxt = new FlxText(meanLine.x + 5, meanLine.y, 0, 'Mean: ${Util.truncateFloat(stats.mean, 4)}ms');
		meanTxt.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 16, 0xFF7984A1, LEFT);

		add(meanTxt);

		stddLine = new FunkinSprite(graphBG.x, getGraphY(stats.standardDeviation, 3));
		stddLine.makeGraphic(1, 1, 0xC0A17998);
		stddLine.scale.set(graphBG.width, 3);
		stddLine.updateHitbox();
		add(stddLine);
		stddTxt = new FlxText(stddLine.x + stddLine.width - 5, stddLine.y, 0, 'Standard Dev.: ${Util.truncateFloat(stats.standardDeviation, 4)}ms');
		stddTxt.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 16, 0xFFA17998, RIGHT);
		stddTxt.x -= stddTxt.width;
		add(stddTxt);

		var near = Math.abs(meanLine.y - stddLine.y) < 50;
		if ((stats.mean < 0) != near)
			meanTxt.y += meanLine.height - meanTxt.height;
		if ((stats.standardDeviation < 0) != near)
			stddTxt.y += stddLine.height - stddTxt.height;

		lateTxt = new FlxText(graphBG.x + 5, graphBG.y + 5, 0, "Late (" + hitWindow + "ms)");
		lateTxt.setFormat(Assets.getPath("fonts/LineSeed.ttf"), 20, 0xFFFFFFFF, LEFT);
		add(lateTxt);
		earlyTxt = new FlxText(graphBG.x + graphBG.width - 5, graphBG.y + graphBG.height - 5, 0, "Early (-" + hitWindow + "ms)");
		earlyTxt.setFormat(Assets.getPath("fonts/LineSeed.ttf"), 20, 0xFFFFFFFF, LEFT);
		earlyTxt.x -= earlyTxt.width;
		earlyTxt.y -= earlyTxt.height;
		add(earlyTxt);

		add(bars = new FlxTypedGroup());
		add(barTxt = new FlxTypedGroup());
		final BAR_HEIGHT = (FlxG.height - (graphBG.height + 20) - 10 - 10 * stats.judgements.length) / (stats.judgements.length + 1);
		for (i in 0...(stats.judgements.length + 1)) {
			var bar = FlxGradient.createGradientFlxSprite(400, Math.floor(BAR_HEIGHT), getGradientColors(i == stats.judgements.length ? stats.missColor : stats.judgements[i].color));
			bar.setPosition(10, graphBG.y + graphBG.height + (BAR_HEIGHT + 10) * i + 10);
			bar.origin.x = 0;
			bar.scale.x = 0;
			bars.add(bar);

			var txt = new FlxText(bar.x + 5, bar.y + bar.height * 0.5, 0, "");
			txt.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 36, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			txt.size = Math.ceil(txt.size * (Math.min(bar.height - 4, txt.height) / txt.height));
			txt.y -= txt.height * 0.5;
			barTxt.add(txt);
		}

		scoreTxt = new FlxText(480, graphBG.y + graphBG.height + 10, 0, "Score: 0");
		scoreTxt.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 36, 0xFFFFFFFF, LEFT);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
		add(scoreTxt);
		accuracyTxt = new FlxText(scoreTxt.x, scoreTxt.y + scoreTxt.height, 0, "Accuracy: 0%");
		accuracyTxt.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 32, 0xFFFFFFFF, LEFT);
		accuracyTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
		add(accuracyTxt);
		notes = new FlxText(accuracyTxt.x, accuracyTxt.y + accuracyTxt.height + 25, 0, "Best/Highest Combo: 0/0\nBest NPS: 0");
		notes.setFormat(Assets.getPath("fonts/LineSeed.ttf"), 28, 0xFFFFFFFF, LEFT);
		notes.setBorderStyle(OUTLINE, 0xFF000000, 2);
		add(notes);

		clearTxt = new SkewedText(FlxG.width - 10, FlxG.height, 0, stats.clearType);
		clearTxt.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 120, stats.clearType.color, RIGHT);
		clearTxt.setBorderStyle(OUTLINE, clearTxt.color.lightness > 0.85 ? 0xFF000000 : 0xFFFFFFFF, 4);
		clearTxt.x -= clearTxt.width;
		clearTxt.y -= clearTxt.height;
		add(clearTxt);

		rankTxt = new SkewedText(clearTxt.x + clearTxt.width, clearTxt.y, 0, stats.grade.type);
		rankTxt.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 56, stats.grade.color, RIGHT);
		rankTxt.setBorderStyle(OUTLINE, rankTxt.color.lightness > 0.2 ? FlxColor.interpolate(rankTxt.color, 0xFF000018, 0.75) : FlxColor.interpolate(rankTxt.color, 0xFFFBCFDD, 0.5), 3);
		rankTxt.x -= rankTxt.width;
		rankTxt.y -= rankTxt.height;
		add(rankTxt);

		diff = new SkewedText(rankTxt.x + rankTxt.width, rankTxt.y, 0, Difficulty.current.toUpperCase());
		diff.setFormat(Assets.getPath("fonts/LineSeed.ttf"), 32, Difficulty.currentColor, RIGHT);
		diff.setBorderStyle(OUTLINE, diff.color.lightness < 0.15 ? 0xFFFFFFFF : 0xFF000000, 2);
		diff.x -= diff.width;
		diff.y -= diff.height;
		add(diff);

		title = new SkewedText(diff.x + diff.width, diff.y, 0, stats.songName);
		title.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 36, 0xFFFFFFFF, RIGHT);
		title.setBorderStyle(OUTLINE, 0xFF000000, 2);
		title.x -= title.width;
		title.y -= title.height;
		add(title);

		tweenObjects();
	}

	function tweenObjects() {
		add(tweens = new FlxTweenManager());
		tweens.active = false; // in case auto-update suddenly works again, and also i think i'd like to cancel out timeScale.

		var scoreLabels = [scoreTxt, accuracyTxt, notes];
		for (i => label in scoreLabels) {
			label.y -= 15;
			label.alpha = 0;
			tweens.tween(label, {y: label.y + 15, alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.2 + 0.1 * i});
		}

		var titleLabels = [title, diff];
		for (i => label in titleLabels) {
			label.x += label.width + 200;
			label.skew.x = -80;
			tweens.tween(label, {x: label.x - label.width - 200, "skew.x": 0}, 0.1, {ease: FlxEase.backOut, startDelay: 0.1 * i});
		}

		var lastSoundTime = 0;
		tick = Util.makeSound(Assets.audio("sfx/scroll"));
		var scoreTwn = tweens.num(0, 1, 2, {ease: FlxEase.quadOut, startDelay: 0.2, onComplete: function(twn) {
			if (exiting) return;

			var sound = FlxG.sound.play(Assets.audio("sfx/confirm"));
			music = Util.makeSound(Assets.audio("music/results"), 1, true);
			music.play();
		}}, function(scale) {
			var soundTime = Math.ceil(scale * 150);
			if (lastSoundTime < soundTime) {
				tick.pitch = soundTime > 149 ? 1 : 1 + scale * 0.5;
				tick.play(true);
				lastSoundTime = soundTime;
			}

			scoreTxt.text = "Score: " + Util.moneyString(Math.round(stats.score * scale));
			accuracyTxt.text = "Accuracy: " + Util.truncateFloat(stats.accuracy * scale, 3) + "%";
			notes.text = 'Best/Highest Combo: ${Math.round(stats.maxCombo * scale)}/${Math.round(stats.hitData.length * scale)}\nBest NPS: ${Math.round(stats.maxNPS * scale)}';
		});

		var ranks = [rankTxt, clearTxt];
		for (i => label in ranks) {
			label.x += label.width + 200;
			label.skew.x = -80;
			tweens.tween(label, {x: label.x - label.width - 200, "skew.x": 0}, 0.1, {ease: FlxEase.backOut, startDelay: scoreTwn.duration});
		}

		timeDot = Assets.image("images/menus/results/noteHitDot");
		missLine = FlxG.bitmap.create(timeDot.width, Std.int(graphBG.frameHeight), 0xFF808080);
		missLine.destroyOnNoUse = false;

		graphBG.y -= 15;
		graphBG.alpha = 0;
		var idx = 0;
		var bgTwn = tweens.tween(graphBG, {y: graphBG.y + 15, alpha: 1}, 0.4, {ease: FlxEase.cubeOut});
		tweens.num(0, 1, 1.5, {startDelay: bgTwn.duration, ease: FlxEase.cubeOut}, function(scale) {
			while (idx < stats.hitData.length && scale * stats.songLength >= stats.hitData[idx].time) {
				final hit = stats.hitData[idx];
				final xPercent = hit.time / stats.songLength;

				final dot = graphDots.recycle(FunkinSprite);
				dot.loadGraphic(hit.comboBreak ? missLine : timeDot);
				dot.setPosition(graphBG.x + (graphBG.width - dot.width) * xPercent, getGraphY(hit.deviation, dot.height));
				dot.offset.x = 20;
				dot.alpha = 0;
				dot.color = hit.comboBreak ? stats.missColor : getJudgeColor(hit.deviation);
				++idx;
			}
		});

		for (i in 0...(stats.judgements.length + 1)) {
			var isMiss = i == stats.judgements.length;
			tweens.num(0, 1, 1.5, {ease: FlxEase.quadOut, startDelay: 0.1 * i}, function(scale) {
				bars.members[i].scale.x = scale * ((isMiss ? stats.misses : stats.judgements[i].hits) / stats.hitData.length);

				barTxt.members[i].x = bars.members[i].x - 15 + 20 * scale;
				barTxt.members[i].text = isMiss ? 'Misses: ${Math.round(stats.misses * scale)}'// (Combo Breaks: ${Math.round(stats.comboBreaks * scale)})'
										: stats.judgements[i].name + ": " + Math.round(stats.judgements[i].hits * scale);
			});
		}
	}

	override function update(delta:Float) {
		tweens.update(delta / FlxG.timeScale);

		if (Controls.justPressed('accept')) {
			exiting = true;
			music?.stop();
			FunkinState.toMenu(new FreeplayState());
		}

		for (dot in graphDots.members) {
			if (!dot.alive) continue;
			
			dot.alpha = FlxMath.lerp(dot.alpha, 1, delta * 5);
			dot.offset.x = 20 * (1.0 - dot.alpha);
			if (dot.alpha > 0.99) {
				graphBG.stamp(dot, Math.round(dot.x - graphBG.x), Math.round(dot.y - graphBG.y));
				dot.kill();
			}
		}
	}

	function getJudgeColor(deviation:Float) {
		for (i in 0...(stats.judgements.length - 1)) {
			if (Math.abs(deviation) <= stats.judgements[i].window)
				return stats.judgements[i].color;
		}
		return stats.judgements[stats.judgements.length - 1].color;
	}
	function getGraphY(deviation:Float, ?height:Float = 6) { // it may not be 6 later on
		return graphBG.y + (graphBG.height - height) * (0.5 - 0.5 * (deviation / hitWindow));
	}
	function getGradientColors(color:FlxColor) {
		return color.lightness > 0.15 ? [color, FlxColor.interpolate(color, 0xFF000018, 0.5)] : [FlxColor.interpolate(color, 0xFFFBCFDD, 0.5), color];
	}
}