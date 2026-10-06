package funkin.core.scoring;

import haxe.Int64;
import funkin.core.accuracy.StepManiaAccuracy.StepManiaScoreEvent;

// https://github.com/stepmania/stepmania/blob/5_1-new/src/ScoreKeeperNormal.cpp#L206
// https://github.com/stepmania/stepmania/blob/5_1-new/src/ScoreKeeperNormal.cpp#L236-335
//
// might be slightly inaccurate ?????
// idk im not getting relatively the same values that i do on sm
class StepManiaScoring extends ScoreHandler {
	// https://github.com/stepmania/stepmania/blob/5_1-new/src/GameState.cpp#L686
	var longLength:Float = (60 * 2.5) * 1000;
	var marathonLength:Float = (60 * 5) * 1000;

	function getLengthMultiplier(songLength:Float):Int {
		var numStages:Int = 1;

		if (songLength >= marathonLength)
			numStages *= 3;
		else if (songLength >= longLength) {
			numStages *= 2;
		}

		return numStages;
	}

	var noteCount:Int;
	public function new(noteCount:Int = 0, songLength:Float) {
		super('StepMania 5');
		this.noteCount = noteCount;

		// long ver and marathon ver songs have higher max possible scores
		var lengthMultiplier:Int = getLengthMultiplier(songLength);

		/* This is no longer just simple additive/subtractive scoring,
		 * but start with capping the score at the size of the score counter. */		
		maxPossiblePoints = 10 * 10000000 * lengthMultiplier;
	}

	var notesHit:Int = 0;
	var combo:Int = 0;

	var pointBonus:Int = 0;
	var curMaxScore:Int = 0;
	var maxPossiblePoints:Int = 0;
	var scoreRemainder:Int = 0;

	function getSMWeight(windowID:Int):Float {
		return switch windowID {
			default: 0;

			case 0: 10;
			case 1: 9; // 10 if no W1
			case 2: 5;
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

	// haxe DOES in fact have 64 bit ints so thanks stepmania
	function _getEquation(p:Int, Z:Int, S:Int64, n:Int):Int {
		return Int64.toInt(Int64.ofInt(p) * n * Z / S);
	}
	
	var current:Int = 0;

	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();

		notesHit++;
		combo++;

		// kinda worried this won't work
		// cuz apparently there's only one score per row ???????
		// but that fucks up like everything
		// ok stepmania
		//
		// just gonna hope it's an old comment from kyz and pray that
		// they ended up changing it
		// cuz it looks like the code doesn't do anything else
		addScoreInternal(Judgement.getID(deviation));
	}

	function addScoreInternal(windowID:Int) {
		var score:StepManiaScoreEvent = getSMScore(windowID);

		// this is *technically* supposed to be a uint but
		// i don't think haxe has a way to do what sm does ??????
		// (see ScoreKeeperNormal.cpp#L285)
		final N:Int64 = noteCount;
		final sum:Int64 = (N * (N + 1)) / 2;
		final Z:Int = Std.int(maxPossiblePoints / 10);
		var p:Int = Std.int(getSMWeight(windowID));

		current += _getEquation(p, Z, sum, notesHit);

		// what the fuck is m_ComboBonusFactor ?????????????????
		current += combo;

		// Subtract the maximum this step could have been worth from the bonus.
		pointBonus -= _getEquation(10, Z, sum, notesHit);

		// And add the maximum this step could have been worth to the max score up to now.
		curMaxScore += _getEquation(10, Z, sum, notesHit);

		if (notesHit == noteCount && (score == TNS_W1 || score == TNS_W2)) {
			current += pointBonus;
			curMaxScore += pointBonus;
		}

		// Undo rounding from the last tap, and re-round.
		current += scoreRemainder;
		scoreRemainder = current % 1;
		current -= scoreRemainder;
	}

	override function noteMissed(_) {
		combo = 0;
	}

	override function sustainHit(sustain:Sustain) {
		addScoreInternal(0);
	}

	override function sustainDropped(_) {
		combo = 0;
		addScoreInternal(3); // required for subtractive score display to work properly.
	}

	override function get(_):Int return current;
}