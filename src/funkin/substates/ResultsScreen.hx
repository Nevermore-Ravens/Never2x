package funkin.substates;

import funkin.core.Statistics;
import flixel.text.FlxText;

class ResultsScreen extends flixel.FlxSubState {
	var stats:Statistics;

	public function new(stats:Statistics) {
		super();
		this.stats = stats;
	}

	override function create():Void {
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;
		add(bg);

		var songText = new FlxText(0, 100, FlxG.width, 'wow oy ubeat ${stats.songName} !!!!!!!!!!!!!!!!!', 50);
		add(songText);

		var mean = new FlxText(0, 500, FlxG.width, 'mean ${Util.truncateFloat(stats.mean, 4)}', 30);
		add(mean);

		var standardDev = new FlxText(0, 550, FlxG.width, 'standard dev ${Util.truncateFloat(stats.standardDeviation, 4)}ms', 30);
		add(standardDev);
	}

	override function update(_) {
		if (FlxG.keys.justPressed.ENTER) {
			FlxG.switchState(new FreeplayState());
		}
	}
}