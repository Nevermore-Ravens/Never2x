package funkin.core.scoring;

class DefaultScoring extends ScoreHandler {
	var current:Int = 0;
	public function new() {
		super('Default');
	}

	override function get(_):Int return current;

	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();
		var window:Float = Judgement.get(deviation).window;

		current += Math.floor(500 - (Math.pow(Math.abs(deviation / window), 2.5) * 300));
	}
}