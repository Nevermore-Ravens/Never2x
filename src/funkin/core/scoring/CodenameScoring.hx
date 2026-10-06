package funkin.core.scoring;

class CodenameScoring extends ScoreHandler {
	var current:Int = 0;
	public function new() {
		super('FNF (Codename)');
	}

	override function get(_):Int return current;

	override function getWeight(deviation:Float):Float {
		var id:Int = Judgement.getID(deviation);

		return switch id {
			default: 0;

			case 0, 1: 300;
			case 2: 200;
			case 3: 100;
			case 4: 50;
		}
	}

	override function noteHit(note:Note, ?deviation:Float) {
		current += Std.int(getWeight(deviation ?? note.getDeviation()));
	}
}