package funkin.core.accuracy;

// fucking kill me
// https://github.com/FunkinCrew/Funkin/blob/develop/source/funkin/play/scoring/Scoring.hx#L430
class VSliceAccuracy extends AccuracyHandler {
	public function new(noteCount:Int) {
		super(VSLICE);
		this.noteCount = noteCount;
	}
	
	override function get(stats:Statistics):Float {
		if (noteCount == 0) return 0.0;

		var killers:Int = judgements[0].hits;
		var sicks:Int = judgements[1].hits;
		var goods:Int = judgements[2].hits;

		return (((killers + sicks) + goods - stats.comboBreaks) / noteCount) * 100;
		// return ((sicks + goods - stats.comboBreaks) / noteCount) * 100;
	}
}