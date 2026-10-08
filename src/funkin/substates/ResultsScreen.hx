package funkin.substates;

import funkin.core.Statistics;
import flixel.text.FlxText;

@:structInit
@:publicFields
class ResultData {
	var song:String = 'Unknown';
	var difficulty:String = 'Unknown';
	var stats:Statistics = null;
}

class ResultsScreen extends flixel.FlxSubState {
	var stats:Statistics;
	var song:String;
	var difficulty:String;

	public function new(data:ResultData) {
		super();
		stats = data.stats;
		song = data.song;
		difficulty = data.difficulty;
	}

	override function create():Void {
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;
		add(bg);

		var songText = new FlxText(0, 100, FlxG.width, 'wow oy ubeat $song !!!!!!!!!!!!!!!!!', 50);
		add(songText);

		var mean = new FlxText(0, 500, FlxG.width, 'mean ${Util.truncateFloat(stats.mean, 4)}', 30);
		add(mean);

		var standardDev = new FlxText(0, 550, FlxG.width, 'standard dev ${Util.truncateFloat(stats.standardDeviation, 4)}', 30);
		add(standardDev);
	}

	override function update(_) {
		if (FlxG.keys.justPressed.ENTER) {
			FlxG.switchState(new FreeplayState());
		}
	}
}