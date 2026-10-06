package funkin.core.scoring;

// https://osu.ppy.sh/wiki/en/Gameplay/Score/ScoreV1/osu%21mania
class OsuScoring extends ScoreHandler {
	var noteCount:Int = 0;
	var maxScore:Int = 1000000;
	var current:Int = 0;
	public function new(noteCount:Int) {
		super('osu!mania (ScoringV1)');
		this.noteCount = noteCount;
	}

	override function getWeight(deviation:Float):Float {
		var id:Int = Judgement.getID(deviation);

		return switch id {
			default: 0;

			case 0: 320;
			case 1: 300;
			case 2: 200;
			case 3: 100;
			case 4: 50;
		}
	}

	// * 2 because there is no bonus score
	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();

		var hitValue:Int = Std.int(getWeight(deviation));
		current += Std.int((maxScore * 0.5 / noteCount) * (hitValue / 320)) * 2;
	}

	override function get(_):Int return current;
}