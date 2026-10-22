package funkin.core.accuracy;

// max/rainbow 300 - marvelous
// 300/gold 300 - sick/perfect
// 200 - good/great
// 100 - bad/good
// 50 - shit/bad/boo
// miss
// https://osu.ppy.sh/wiki/en/Gameplay/Accuracy#osu!mania
class OsuAccuracy extends AccuracyHandler {
	public function new() {
		super(OSU_MANIA);
	}

	override function get(stats:Statistics):Float {
		var judgementCount:Int = stats.noteHits + stats.comboBreaks;
		if (judgementCount == 0) return 100.0;

		var max:Int = stats.judgements[0].hits;
		var sicks:Int = stats.judgements[1].hits;
		var goods:Int = stats.judgements[2].hits;
		var bads:Int = stats.judgements[3].hits;
		var shits:Int = stats.judgements[4].hits;

		return (300 * (max + sicks) + 200 * goods + 100 * bads + 50 * shits) /
		(300 * (max + sicks + goods + bads + shits + stats.comboBreaks)) * 100;
	}
}