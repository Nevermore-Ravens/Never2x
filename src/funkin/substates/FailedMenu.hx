package funkin.substates;

class FailedMenu extends FunkinSubstate {
	var stats:N2XStatistics;

	public function new(stats:N2XStatistics) {
		super();
		this.stats = stats;
	}

	override function create():Void {
		super.create();

		Conductor.inst = Util.makeSound(Assets.audio('sfx/gameover-loop.ogg'), 1, true);
		Conductor.vocals = null;
		Conductor.clock.timingMap.reset([{time: 0, tempo: 100}]);
		Conductor.clock.offset = 0;

		var font = Assets.getPath('fonts/LineSeed.ttf');

		// 5, 5
		// height 69 
		var failed:FlxText = new FlxText(5, 0, 0, 'You failed...', 40);
		failed.color = 0xFFFF0000;
		failed.font = font;
		add(failed);
		failed.y = -failed.height;
		failed.alpha = 0;

		var current:String = flixel.util.FlxStringUtil.formatTime(stats.songTime * 0.001, false);
		var duration:String = flixel.util.FlxStringUtil.formatTime(stats.songLength * 0.001, false);

		// 5, 74
		// height 53
		var songName:FlxText = new FlxText(5, 74, 0, stats.songName + ' ($current / $duration)', 30);
		songName.font = font;
		songName.alpha = 0;
		add(songName);

		// 5, 127
		var difficulty:FlxText = new FlxText(5, 127, 0, stats.difficulty, 25);
		difficulty.font = font;
		difficulty.alpha = 0;
		add(difficulty);

		// 
		var judgements:FlxText = new FlxText(0, 0, 700, '', 25);
		judgements.font = font;
		judgements.alignment = 'right';
		add(judgements);

		for (judge in stats.judgements) {
			judgements.text += judge.name + 's: ' + judge.hits + '\n';
		}

		judgements.text += 'Misses: ' + stats.misses + '\n';
		judgements.text += 'Combo breaks: ' + stats.comboBreaks;
		judgements.x = FlxG.width;
		judgements.screenCenter(Y);
		judgements.alpha = 0;

		// FlxG.height - mean.height
		var mean:FlxText = new FlxText(5, 0, 500, 'Mean: ' + Util.truncateFloat(stats.mean, 3) + 'ms', 25);
		mean.text += '\nStd. Deviation: ' + Util.truncateFloat(stats.standardDeviation, 3) + 'ms';
		mean.font = font;
		add(mean);
		mean.y = FlxG.height;
		mean.alpha = 0;

		var controls:FlxText = new FlxText(0, 0, 700, 'Press ENTER to retry\nPress ESCAPE to quit', 30);
		controls.font = font;
		controls.alignment = 'right';
		add(controls);
		controls.x = (FlxG.width - controls.width) - 10;
		controls.y = (FlxG.height - controls.height);
		controls.alpha = 0;

		FlxG.sound.play(Assets.audio('sfx/gameover-start.ogg'));
		new FlxTimer().start(1.062, function(_) {
			FlxTween.tween(failed, {y: 5}, 1.5, {ease: FlxEase.cubeOut});
			FlxTween.tween(failed, {alpha: 1}, 3, {ease: FlxEase.cubeOut});

			FlxTween.tween(songName, {alpha: 1}, 3, {ease: FlxEase.cubeOut});
			FlxTween.tween(difficulty, {alpha: 1}, 3, {ease: FlxEase.cubeOut});
			
			FlxTween.tween(judgements, {x: (FlxG.width - judgements.width) - 10, alpha: 1}, 2, {ease: FlxEase.cubeOut});
			FlxTween.tween(mean, {y: FlxG.height - mean.height, alpha: 1}, 2, {ease: FlxEase.cubeOut});
		});

		new FlxTimer().start(3, function(_) {
			Conductor.play();
			inputs = true;

			FlxTween.tween(controls, {alpha: 1}, 2.5, {ease: FlxEase.cubeOut});
		});
	}

	var accepted:Bool = false;
	var inputs:Bool = false;
	override function update(delta:Float) {
		if (!inputs || accepted) return;

		if (FlxG.keys.justPressed.ENTER) {
			camera.flash(0xFF999999, 2);
			for (obj in members) obj.visible = false;

			accepted = true;
			FlxG.sound.play(Assets.audio('sfx/gameover-confirm.ogg'));
			FlxTween.num(1, 0, 1, function(num:Float) Conductor.inst.volume = num);
			new FlxTimer().start(4, function(_) {
				FlxG.resetState();
			});
		}
	}
}