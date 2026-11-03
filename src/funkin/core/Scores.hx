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
	public static var weekList:Array<WeekPlayData> = [];

	static var _save:FlxSave;

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		list.resize(0);
		if (_save.data.list != null) list = _save.data.list.copy();
		if (_save.data.weekList != null) weekList = _save.data.weekList.copy();

		trace(list);
	}

	public static function save():Void {
		_save.data.list = list.copy();
		_save.data.weekList = weekList.copy();
		_save.flush();
	}

	////////////////////////////////
	// WEEKS
	////////////////////////////////

	public static function getWeekPlay(weekID:String, ?difficulty:String):WeekPlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<WeekPlayData> = filterWeekPlays(weekList, weekID, difficulty);
		if (plays.length == 0) {
			return {
				weekID: weekID,
				difficulty: difficulty,
				score: 0,

				modifiers: []
			}
		}

		return plays[0];
	}

	public static function setWeekPlay(data:WeekPlayData):Void {
		var filteredList:Array<WeekPlayData> = filterWeekPlays(weekList, data.weekID, data.difficulty);

		if (filteredList.length == 0) {
			weekList.push(data);
			return;
		}

		var oldPlay:WeekPlayData = weekList[weekList.indexOf(filteredList[0])];
		if (oldPlay.score < data.score) oldPlay.score = data.score;
	}

	public static function filterWeekPlays(plays:Array<WeekPlayData>, weekID:String, difficulty:String):Array<WeekPlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplayModifiers.copy();

		return plays.filter(function(play:WeekPlayData) {
			for (m in ['playbackRate', 'onlySicks', 'mirroredNotes', 'playingSide']) {
				if (!play.modifiers.exists(m) || play.modifiers[m] != modifiers[m]) return false;
			}

			return play.weekID == weekID && play.difficulty == difficulty;
		});
	}

	////////////////////////////
	// PLAYS
	////////////////////////////

	public static function getPlay(songID:String, ?difficulty:String, ?hasModchart:Bool = false):PlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<PlayData> = filterPlays(list, songID, difficulty, hasModchart);
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

	public static function setPlay(data:PlayData, ?hasModchart:Bool = false):Void {
		var filteredList:Array<PlayData> = filterPlays(list, data.songID, data.difficulty, hasModchart);

		if (filteredList.length == 0) {
			list.push(data);
			trace(list);
			return;
		}

		var oldPlay:PlayData = list[list.indexOf(filteredList[0])];

		if (oldPlay.accuracy < data.accuracy) {
			oldPlay.accuracy = data.accuracy;
		}

		if (oldPlay.score < data.score) {
			oldPlay.score = data.score;
		}

		trace(list);
	}

	public static function filterPlays(plays:Array<PlayData>, songID:String, difficulty:String, ?hasModchart:Bool = false):Array<PlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplayModifiers.copy();

		return plays.filter(function(play:PlayData) {
			if (hasModchart && (!play.modifiers.exists("modcharts") || play.modifiers["modcharts"] != modifiers["modcharts"])) return false;

			for (m in ['playbackRate', 'onlySicks', 'mirroredNotes', 'playingSide' #if SV_ALLOWED , 'svs' #end]) {
				if (!play.modifiers.exists(m) || play.modifiers[m] != modifiers[m]) return false;
			}
			#if !SV_ALLOWED 
			if(!play.modifiers.exists("svs") || play.modifiers["svs"] == true)return false;
			#end

			return play.songID == songID && play.difficulty == difficulty;
		});
	}
}