package funkin.core.scoring;

class ScoreHandler {
	public var judgements(get, default):Array<Judgement>;
	function get_judgements():Array<Judgement> {
		judgements ??= Judgement.current;
		return judgements;
	}

	public var type:String;
	public function new(?type:String = 'Unknown') {
		this.type = type;
	}

	public function getWeight(deviation:Float):Float return 0.0;

	public function noteHit(note:Note, ?deviation:Float) {}
	public function noteMissed(note:Note) {}
	public function sustainHit(sustain:Sustain) {}
	public function sustainDropped(sustain:Sustain) {}

	public function get(stats:Statistics):Int {
		return 0;
	}
}