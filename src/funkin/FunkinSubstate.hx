package funkin;

class FunkinSubstate extends flixel.FlxSubState {
	override function create() {
		Conductor.clock.stepHit.add(stepHit);
		Conductor.clock.beatHit.add(beatHit);
		Conductor.clock.measureHit.add(measureHit);
	}

	override function close() {
		Conductor.clock.stepHit.remove(stepHit);
		Conductor.clock.beatHit.remove(beatHit);
		Conductor.clock.measureHit.remove(measureHit);
	}

	public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}
}