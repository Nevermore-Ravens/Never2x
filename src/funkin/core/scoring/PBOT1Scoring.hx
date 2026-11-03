package funkin.core.scoring;

// fucking kill me 
// again
// https://github.com/FunkinCrew/Funkin/blob/develop/source/funkin/play/scoring/Scoring.hx#L96-181
class PBOT1Scoring extends ScoreHandler {
	public function new() {
		super('PBOT1 (FNF (V-Slice))');
	}

	override function get(_):Int return current;

	
	var current:Int = 0;

	var missScore:Int = -100;
  	var maxScore:Int = 500;
	var scoringOffset:Float = 54.99;
	var scoringSlope:Float = 0.080;
	var minScore:Float = 9.0;
	var perfectThreshold:Float = 5.0;
	function _pbot1(deviation:Float):Int {
		deviation = Math.abs(deviation);

		if (deviation > Judgement.max.window) {
			return missScore;
		}

		if (deviation < perfectThreshold) {
			return maxScore;
		}

		// Fancy equation.
		// -EliteMasterEric, 2024
		var offset:Float = deviation - scoringOffset;
		var curve:Float = 1.0 + Math.exp(-scoringSlope * offset);
		var factor:Float = 1.0 - (1.0 / curve);

		return Std.int(maxScore * factor + minScore);
	}

	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();
		current += _pbot1(deviation);
	}

	// https://github.com/FunkinCrew/Funkin/blob/develop/source/funkin/play/PlayState.hx#L2924
	// dude what the fuck
	override function noteMissed(_) current -= 100;
	override function sustainDropped(sustain:Sustain) {
		if (sustain.length <= 160) return;

  		// Different penalty based on whether the note itself was missed,
        // or the note was hit and then the hold was dropped.
        var remainingLengthSec:Float = sustain.length / 1000;
        // If the base note of the hold was missed, don't penalize them more on top of that.
        var scoreChange:Float = -125 * remainingLengthSec;

		current += scoreChange;
	}

	// not exact because vslice increments it per-frame
	// when we're incrementing it in intervals
	override function sustainHit(_) {
		current += 250 * FlxG.elapsed;
	}
}