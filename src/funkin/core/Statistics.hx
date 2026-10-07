package funkin.core;

enum abstract ClearType(String) from String to String {
	var CLEARTYPE_DEFAULT = 'N/A';
	var KILLER_FULL_COMBO = 'KFC'; // kentucky full combo
	var WHITE_FLAG = 'WF';
	var SINGLE_DIGIT_SICK = 'SDS';
	var SICK_FULL_COMBO = 'SFC';
	var BLACK_FLAG = 'BF';
	var SINGLE_DIGIT_GOOD = 'SDG';
	var GOOD_FULL_COMBO = 'GFC';
	var FULL_COMBO = 'FC';
	var MISS_FLAG = 'MF';
	var SINGLE_DIGIT_COMBO_BREAK = 'SDCB';
	var CLEAR = 'Clear';

	public var color(get, never):FlxColor;
	function get_color():FlxColor {
		return switch this {
			default: 0xFFFFFFFF;

			case KILLER_FULL_COMBO: 0xFFDDFF00;
			case WHITE_FLAG: 0xFFDDFF00;
			case SINGLE_DIGIT_SICK: 0xFFDDFF00;
			case SICK_FULL_COMBO: 0xFFDCAB24;
			case BLACK_FLAG: 0xFF3EC53E;
			case SINGLE_DIGIT_GOOD: 0xFF3EC53E;
			case GOOD_FULL_COMBO: 0xFF3EC53E;
			case FULL_COMBO: 0xFF0090FF;
			case MISS_FLAG: 0xFF000000;
			case SINGLE_DIGIT_COMBO_BREAK: 0xFF000000;
			case CLEAR: 0xFF000000;
			case CLEARTYPE_DEFAULT: 0xFF808080;
		}
	}
}

enum abstract GradeType(String) from String to String {
	var GRADETYPE_DEFAULT = '?';
}

@:structInit
@:publicFields
class NoteHitData {
	var time:Int = 0;
	var deviation:Float = 0;
	var countMean:Bool = true;
}

@:structInit
@:publicFields
class Statistics {
	var fails:Int = 0;

	var judgements:Array<Judgement> = Judgement.current;

	var score:Int = 0;
	var comboBreaks:Int = 0;
	var accuracy:Float = 0.0;
	var combo:Int = 0;
	var highestCombo:Int = 0;
	var notesHit:Int = 0;

	// not calculated until the song ends
	var mean:Float = 0.0; 
	var standardDeviation:Float = 0.0;
	
	var noteHits:Array<NoteHitData> = [];

	static function getClearType(stats:Statistics):ClearType {
		var type:ClearType = CLEARTYPE_DEFAULT;

		var killers:Int = stats.judgements[0].hits;
		var sicks:Int = stats.judgements[1].hits;
		var goods:Int = stats.judgements[2].hits;
		var bads:Int = stats.judgements[3].hits;
		var shits:Int = stats.judgements[4].hits;

		if (stats.comboBreaks == 0) {
			if (bads > 0) type = FULL_COMBO;
			else if (goods > 0) {
				if (goods == 1) type = BLACK_FLAG;
				else if (goods <= 9) type = SINGLE_DIGIT_GOOD;
				else type = GOOD_FULL_COMBO;
			} else if (sicks > 0) {
				if (sicks == 1) type = WHITE_FLAG;
				else if (sicks <= 9) type = SINGLE_DIGIT_SICK;
				else type = SICK_FULL_COMBO;
			} else if (killers > 0) type = KILLER_FULL_COMBO;
		} else {
			if (stats.comboBreaks == 1) type = MISS_FLAG;
			else if (stats.comboBreaks <= 9) type = SINGLE_DIGIT_COMBO_BREAK;
			else type = CLEAR;
		}

		return type;
	}

	// TODO
	static function getGrade(stats:Statistics):GradeType {
		return GRADETYPE_DEFAULT;
	}
}