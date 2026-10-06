package funkin.core.accuracy;

enum StepManiaScoreEvent {
	HNS_Held;
	HNS_LetGo;
	HNS_Missed;
	TNS_HitMine;
	TNS_Miss;
	TNS_None;

	TNS_W1; // marvs
	TNS_W2; // perfects
	TNS_W3; // greats
	TNS_W4; // goods
	TNS_W5; // bads
}

// https://github.com/stepmania/stepmania/blob/5_1-new/Themes/_fallback/metrics.ini#L1375
// https://github.com/stepmania/stepmania/blob/5_1-new/src/ScoreKeeperNormal.cpp
// https://github.com/stepmania/stepmania/blob/5_1-new/src/PlayerStageStats.cpp#L246
//
// this is supposed to count up from 0
// but i couldn't find the code where it does that
// so i guess it just Doesn't
class StepManiaAccuracy extends AccuracyHandler {
	public function new() {
		super ('StepMania 5 (Dance Points)');
	}

	public var holdHeld:Int = 3;
	public var mineHit:Int = -2;
	public var missedHold:Int = 0;
	public var holdDropped:Int = 0;
	public var missedNote:Int = 0;

	var curPossibleDancePoints:Int = 0;
	var actualDancePoints:Int = 0;

	function getSMWeight(windowID:Int) {
		return switch windowID {
			case 0: 3;
			case 1: 2;
			case 2: 1;
			default: 0;
		}
	}

	function getSMScore(windowID:Int):StepManiaScoreEvent {
		return switch windowID {
			default: TNS_None;
			case 0: TNS_W1;
			case 1: TNS_W2;
			case 2: TNS_W3;
			case 3: TNS_W4;
			case 4: TNS_W5;
		}
	}

	function getPossibleDancePoints(note:Note) {
		var ret:Int = 0;
		ret += tapNoteScoreToDancePoints(TNS_W1);
		ret += holdNoteScoreToDancePoints(HNS_Held) * 2; // * 2 for rolls

		return ret;
	}

	function tapNoteScoreToDancePoints(tns:StepManiaScoreEvent):Int {
		return switch tns {
			default: 0;

			case TNS_HitMine: mineHit;
			case TNS_Miss: missedNote;
			case TNS_W5: getSMWeight(4);
			case TNS_W4: getSMWeight(3);
			case TNS_W3: getSMWeight(2);
			case TNS_W2: getSMWeight(1);
			case TNS_W1: getSMWeight(0);
		}
	}

	function holdNoteScoreToDancePoints(hns:StepManiaScoreEvent):Int {
		return switch hns {
			default: 0;

			case HNS_LetGo: holdDropped;
			case HNS_Held: holdHeld;
			case HNS_Missed: missedNote;
		}
	}

	function handleTapNoteScoreInternal(tns:StepManiaScoreEvent, maximum:StepManiaScoreEvent) {
		// Update dance points.
		actualDancePoints += tapNoteScoreToDancePoints(tns);

		// increment the current total possible dance score
		curPossibleDancePoints += tapNoteScoreToDancePoints(maximum);
	}

	function handleHoldScore(hns:StepManiaScoreEvent) {
		// update dance points totals
		actualDancePoints += holdNoteScoreToDancePoints(hns);

		// increment the current total possible dance score
		curPossibleDancePoints += holdNoteScoreToDancePoints(HNS_Held);
	}

	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();

		var smScore:StepManiaScoreEvent = getSMScore(HitWindows.getID(deviation));
		if (note.behavior.punishable) smScore = TNS_HitMine;
		else if (note.length > 0) {
			handleHoldScore(HNS_Held);
		}

		handleTapNoteScoreInternal(smScore, TNS_W1);
	}

	override function noteMissed(_) {
		handleTapNoteScoreInternal(TNS_Miss, TNS_W1);
	}

	override function sustainDropped(_) {
		handleHoldScore(HNS_LetGo);
	}

	override function get(_):Float {
		var result:Float = 0.0;

		if (curPossibleDancePoints == 0) 
			return result;

		if (actualDancePoints == curPossibleDancePoints)
			return 100.0;

		var percent:Float = actualDancePoints / curPossibleDancePoints;

		// don't allow negative
		percent = Math.max(0.0, percent);

		var percentTotalDigits:Int = 5;

		// TRICKY: printf will round, but we want to truncate. Otherwise, we may display
		// a percent score that's too high and doesn't match up with the calculated grade.
		var truncInterval:Float = Math.pow(0.1, percentTotalDigits - 1);

		// TRICKY: ftruncf is rounding 1.0000000 to 0.99990004. Give a little boost
		// to fPercentDancePoints to correct for this.
		percent += 0.000001;

		percent = ftruncf(percent, truncInterval);
		return percent * 100;
	}

	/* return f truncated to the nearest multiple of fTruncInterval */
	inline function ftruncf(f:Float, truncInterval:Float):Float {
		return Std.int(f / truncInterval) * truncInterval;
	}
}
