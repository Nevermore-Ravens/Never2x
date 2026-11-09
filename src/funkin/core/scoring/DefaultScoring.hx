package funkin.core.scoring;

class DefaultScoring extends ScoreHandler {
	var current:Int = 0;
	public function new() {
		super('Default');
	}

	override function get(_):Int return current;

	// temporary fix for now but this is probably how the scoring curve should work from now on
	//
	// 500 should still be the max score you can get for a hit, and the curve should max out at killers/marvs
	// i want something adjacent to wife3 but not EXACT
	// since this is still fnf, and wife3 is way too strict
	// when the deviation gets past killers, it should start dipping relatively slowly
	// past the middle point of sick's window (around ~67.5 ms) is when the scoring curve should start dipping like a normal curve
	// around the middle part of good's window (around ~112.5 ms) is when scoring should (mostly) plummet
	// and barely give you anything at all
	//
	// i feel like this is strict, but not TOO strict in the context of fnf ????
	// still very possible to achieve and encourages you to get better
	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();
		var window:Float = note.judgement.window;

		deviation = Math.max(Math.abs(deviation), Judgement.min.window);
		current += Math.floor(500 - (Math.pow(deviation / window, 2.5) * 300));
	}
}