package funkin.core;

enum abstract ClearType(String) from String to String {
	var CLEARTYPE_DEFAULT = 'N/A';
	var KILLER_FULL_COMBO = 'KFC'; // kentucky fried combo
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

			case KILLER_FULL_COMBO: 0xFF8ACCFF;
			case WHITE_FLAG: 0xFF8ACCFF;
			case SINGLE_DIGIT_SICK: 0xFFFFED5E;
			case SICK_FULL_COMBO: 0xFFFFED5E;
			case BLACK_FLAG: 0xFF5EF95E;
			case SINGLE_DIGIT_GOOD: 0xFF5EF95E;
			case GOOD_FULL_COMBO: 0xFF5EF95E;
			case FULL_COMBO: 0xFFFFFFFF;
			case MISS_FLAG: 0xFFFF0000;
			case SINGLE_DIGIT_COMBO_BREAK: 0xFF990000;
			case CLEARTYPE_DEFAULT: 0xFF808080;
		}
	}
}

enum abstract GradeType(String) from String to String {
	var GRADE_DEFAULT = '?';

	var GRADE_X = 'X';
	var GRADE_SPLUS = 'S+';
	var GRADE_S = 'S';
	var GRADE_A = 'A';
	var GRADE_B = 'B';
	var GRADE_C = 'C';
	var GRADE_D = 'D';
	var GRADE_F = 'F';
}

@:structInit
@:publicFields
class Grade {
	var type:GradeType = GRADE_DEFAULT;
	var accuracy:Float = 0.0;
	var color:FlxColor = 0xFFFFFFFF;
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
	static var grades:Array<Grade> = [
		{type: GRADE_X, accuracy: 100, color: 0xFF8BE4FF},
		{type: GRADE_SPLUS, accuracy: 99, color: 0xFFFFED49},
		{type: GRADE_S, accuracy: 95, color: 0xFFFFC549},
		{type: GRADE_A, accuracy: 90, color: 0xFF52FF52},
		{type: GRADE_B, accuracy: 80, color: 0xFF6898FF},
		{type: GRADE_C, accuracy: 70, color: 0xFFB373BB},
		{type: GRADE_D, accuracy: 60, color: 0xFFFF3A3A},
		{type: GRADE_F, accuracy: 0, color: 0xFF27060D},
	];

	var fails:Int = 0;

	var judgements:Array<Judgement> = Judgement.current;

	var score:Int = 0;

	// combo breaks and misses are NOT the same thing !!
	// misses are for when you completely *miss* hitting a note and it goes off screen
	//
	// combo breaks are the more broader term for that
	// it includes both misses *and* judgements that cause you to lose a combo
	// (in n2x's case, shits break your combo)
	// hence the name "combo breaks"
	// it's how many times your combo has been set to 0, or "broken"
	var comboBreaks:Int = 0;
	var misses:Int = 0;

	var accuracy:Float = 0.0;
	var combo:Int = 0;
	var highestCombo:Int = 0;
	var notesHit:Int = 0;
	var clearType:ClearType = CLEARTYPE_DEFAULT;
	var grade:Grade = grades[grades.length - 1];

	// not calculated until the song ends
	var mean:Float = 0.0; 
	var standardDeviation:Float = 0.0;
	
	var noteHits:Array<NoteHitData> = [];

	function getClearType():ClearType {
		var type:ClearType = CLEARTYPE_DEFAULT;

		var killers:Int = judgements[0].hits;
		var sicks:Int = judgements[1].hits;
		var goods:Int = judgements[2].hits;
		var bads:Int = judgements[3].hits;
		var shits:Int = judgements[4].hits;

		if (comboBreaks == 0) {
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
			if (comboBreaks == 1) type = MISS_FLAG;
			else if (comboBreaks <= 9) type = SINGLE_DIGIT_COMBO_BREAK;
			else type = CLEAR;
		}

		return type;
	}

	function getGrade():Grade {
		for (grade in grades) {
			if (accuracy < grade.accuracy) continue;
			return grade;
		}

		return grades[grades.length - 1];
	}
}