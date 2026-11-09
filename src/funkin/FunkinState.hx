package funkin;

class FunkinState extends flixel.FlxState {
	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;
	
	override function create() {
		Conductor.reset();
		Conductor.clock.active = false;

		Conductor.clock.stepHit.add(stepHit);
		Conductor.clock.beatHit.add(beatHit);
		Conductor.clock.measureHit.add(measureHit);

		if (!skipNextTransOut) {
			openSubState(new Transition(0.5, true));
		} else skipNextTransOut = false;
	}

	public static function toMenu(target:FlxState) {
		if (Conductor.vocals != null) {
			Conductor.vocals.destroy();
			Conductor.vocals = null;
		}

		Conductor.inst = Util.makeSound(Assets.audio('music/freakyMenu'), true);
		Conductor.clock.timingMap.reset([{tempo: 102}]);
		Conductor.play();
		Addons.current = null;

		FunkinState.switchState(target);
	}

	// i am so sorry (this is just taken directly from psych im not trying to bother with flixel's transition bs
	public static function switchState(nextState:FlxState = null) {
		nextState ??= FlxG.state;
		if (nextState == FlxG.state) {
			resetState();
			return;
		}

		if (!Settings.data.transitions || skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		skipNextTransIn = false;
	}

	public static function resetState() {
		if (!Settings.data.transitions || skipNextTransIn) FlxG.resetState();
		else startTransition();
		skipNextTransIn = false;
	}

	public static function startTransition(?nextState:FlxState) {
		if (nextState == null) nextState = FlxG.state;

		FlxG.state.openSubState(new Transition(0.5, false));
		Transition.finishCallback = function() {
			if (nextState == FlxG.state) FlxG.resetState();
			else FlxG.switchState(nextState);
		}
	}

	public static function getState():FunkinState {
		return cast(FlxG.state, FunkinState);
	}

	public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}
}
