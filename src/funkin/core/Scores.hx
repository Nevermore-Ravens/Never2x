package funkin.core;

import flixel.util.FlxSave;

@:structInit
class WeekPlayData {
	public var weekID:String;
	public var difficulty:String;
	public var score:Int;
	public var modifiers:Map<String, Dynamic>;

	public function copy(?copyMods:Bool = true):WeekPlayData {
		return {
			weekID: weekID,
			difficulty: difficulty,
			score: score,
			
			modifiers: copyMods ? modifiers.copy() : modifiers
		};
	}
}

@:structInit
class PlayData {
	// song data
	public var songID:String;
	public var difficulty:String;

	// play data
	public var score:Int;
	public var accuracy:Float;

	public var modifiers:Map<String, Dynamic>;

	public function copy(?copyMods:Bool = true):PlayData {
		return {
			songID: songID,
			difficulty: difficulty,

			score: score,
			accuracy: accuracy,
			
			modifiers: copyMods ? modifiers.copy() : modifiers
		};
	}

	public function toString() {
		return 'Song: ' + songID + ' | Difficulty: ' + difficulty + ' | Score: ' + score + ' | Accuracy: ' + Util.truncateFloat(accuracy, 3) + '%';
	}
}

class Scores {
	public static var list:Array<PlayData> = [];

	// any of these modifiers automatically make
	// a score unique/separate from other scores
	public static var uniqueMods:Array<String> = [
		'playbackRate', 
		'onlySicks', 
		'mirroredNotes', 
		'randomizedNotes', 
		'playingSide' 
		#if SV_ALLOWED 
		, 'svs'
		#end
	];

	static var _save:FlxSave;

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		list.resize(0);
		if (_save.data.list != null) list = _save.data.list.copy();

		trace(list);
	}

	public static function save():Void {
		_save.data.list = list.copy();
		_save.flush();
	}

	public static function reset(?writeToDisk:Bool = true) {
		list.resize(0); 
	}

	public static function get(songID:String, ?difficulty:String, ?hasModchart:Bool = false):PlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<PlayData> = filter(list, songID, difficulty, hasModchart);
		if (plays.length == 0) {
			return {
				songID: songID,
				difficulty: difficulty,
				score: 0,
				accuracy: 0.0,

				modifiers: []
			}
		}

		return plays[0];
	}

	public static function set(data:PlayData, ?hasModchart:Bool = false):Void {
		var filteredList:Array<PlayData> = filter(list, data.songID, data.difficulty, hasModchart);

		if (filteredList.length == 0) {
			list.push(data);
			return;
		}

		var oldPlay:PlayData = list[list.indexOf(filteredList[0])];

		if (oldPlay.accuracy < data.accuracy) {
			oldPlay.accuracy = data.accuracy;
		}

		if (oldPlay.score < data.score) {
			oldPlay.score = data.score;
		}
	}

	public static function filter(plays:Array<PlayData>, songID:String, difficulty:String, ?hasModchart:Bool = false):Array<PlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplayModifiers.copy();

		return plays.filter(function(play:PlayData) {
			if (hasModchart && (!play.modifiers.exists("modcharts") || play.modifiers["modcharts"] != modifiers["modcharts"])) return false;

			for (m in uniqueMods) {
				if (!play.modifiers.exists(m) || play.modifiers[m] != modifiers[m]) return false;
			}

			#if !SV_ALLOWED 
			if(!play.modifiers.exists("svs") || play.modifiers["svs"] == true)return false;
			#end

			return play.songID == songID && play.difficulty == difficulty;
		});
	}
}