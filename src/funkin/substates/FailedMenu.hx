package funkin.substates;

class FailedMenu extends flixel.FlxSubState {
	var stats:Statistics;

	public function new(stats:Statistics) {
		super();
		this.stats = stats;
	}

	override function create():Void {
		var failed:FlxText = new FlxText(5, 5, 0, 'You failed...', 40);
		failed.color = 0xFFFF0000;
		failed.font = Assets.getPath('fonts/LineSeed.ttf');
		add(failed);

		var songName:FlxText = new FlxText(5, (failed.y + failed.height), 0, stats.songName, 30);
		songName.font = Assets.getPath('fonts/LineSeed.ttf');
		add(songName);

		var difficulty:FlxText = new FlxText(5, (songName.y + songName.height), 0, stats.difficulty, 25);
		difficulty.font = Assets.getPath('fonts/LineSeed.ttf');
		add(difficulty);

		var judgements:FlxText = new FlxText(0, 0, 700, '', 30);
		judgements.font = Assets.getPath('fonts/LineSeed.ttf');
		judgements.alignment = 'right';
		add(judgements);

		for (judge in stats.judgements) {
			judgements.text += judge.name + 's: ' + judge.hits + '\n';
		}

		judgements.text += 'Misses: ' + stats.misses + '\n';
		judgements.text += 'Combo breaks: ' + stats.comboBreaks;
		judgements.x = (FlxG.width - judgements.width) - 10;
		judgements.screenCenter(Y);

		var mean:FlxText = new FlxText(5, 0, 500, 'Mean: ' + stats.mean + 'ms', 30);
		mean.text += '\nStd. Deviation: ' + stats.standardDeviation + 'ms';
		mean.font = Assets.getPath('fonts/LineSeed.ttf');
		add(mean);
		mean.y = (FlxG.height - mean.height);

		var controls:FlxText = new FlxText(0, 0, 700, 'Press ENTER to retry\nPress ESCAPE to go back', 30);
		controls.font = Assets.getPath('fonts/LineSeed.ttf');
		controls.alignment = 'right';
		add(controls);
		controls.x = (FlxG.width - controls.width) - 10;
		controls.y = (FlxG.height - controls.height);
	}

	override function update(delta:Float) {
		if (FlxG.keys.justPressed.ENTER) {
			FlxG.resetState();
		}
	}
}