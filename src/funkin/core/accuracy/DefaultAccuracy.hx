package funkin.core.accuracy;

class DefaultAccuracy extends AccuracyHandler {
	var notesPlayed:Float = 0.0;
	public function new() {
		super(DEFAULT_ACCURACY);
	}

	override function getWeight(deviation:Float):Float {
		return switch Judgement.getID(deviation) {
			case 0, 1: 100; // marvs and sicks
			case 2: 85; // goods
			case 3: 45; // bads
			case 4: 30; // shits

			default: 0;
		}
	}

	override function noteHit(note:Note, ?deviation:Float) {
		notesPlayed += getWeight(deviation ?? note.getDeviation());
	}

	// average of all weights
	override function get(stats:Statistics):Float {
		if (stats.noteHits == 0) return 0.0;
		return notesPlayed / (stats.noteHits + stats.comboBreaks);
	}
}