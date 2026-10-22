package funkin.core.accuracy;

// https://github.com/Quaver/Quaver.API/blob/master/Quaver.API/Maps/Processors/Scoring/ScoreProcessorKeys.cs#132
// https://github.com/Quaver/Quaver.API/blob/master/Quaver.API/Maps/Processors/Scoring/ScoreProcessorKeys.cs#337
class QuaverAccuracy extends AccuracyHandler {
	var notesPlayed:Float = 0.0;
	public function new() {
		super(QUAVER);
	}

	override function getWeight(deviation:Float):Float {
		return switch Judgement.getID(deviation) {
			case 0: // marvs
				100;

			case 1: // perfects
				98.25;

			case 2: // great
				65;

			case 3: // good
				25;

			case 4: // okay
				-100; // jesus christ quaver

			default:
				0;
		}
	}

	override function noteHit(note:Note, ?deviation:Float) {;
		notesPlayed += getWeight(deviation ?? note.getDeviation());
	}

	override function noteMissed(_) notesPlayed -= 50;
	override function sustainDropped(_) notesPlayed -= 50;

	override function get(stats:Statistics):Float {
		if (stats.noteHits == 0) return 0.0;

		var minWeight:Float = getWeight(0);
		var judgementCount:Int = stats.noteHits + stats.comboBreaks;

		var mean:Float = notesPlayed / (judgementCount * minWeight);
		return Math.max(mean, 0) * minWeight;
	}
}