package funkin.core.accuracy;

class CodenameAccuracy extends AccuracyHandler {
	var notesPlayed:Float = 0.0;
	public function new() {
		super('FNF (Codename)');
	}

	override function getWeight(deviation:Float):Float {
		return switch Judgement.getID(devation); {
			default: 0;

			case 0, 1: 100;
			case 2: 75;
			case 3: 45;
			case 4: 25;
		}
	}

	override function noteHit(note:Note, ?deviation:Float) {
		notesPlayed += getWeight(deviation ?? note.getDeviation());
	}

	// average of all weights
	override function get(stats:Statistics):Float {
		if (stats.notesHit == 0) return 0.0;
		return notesPlayed / (stats.notesHit + stats.comboBreaks);
	}
}