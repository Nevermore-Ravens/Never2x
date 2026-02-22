package funkin.modchart.mods;

class Beat extends BaseModifier {
	var beat:ModifierValue = 0;
	var beatOffset:ModifierValue = 0;
	var beatPeriod:ModifierValue = 0;
	var beatMult:ModifierValue = 0;

	var beatY:ModifierValue = 0;
	var beatYOffset:ModifierValue = 0;
	var beatYPeriod:ModifierValue = 0;
	var beatYMult:ModifierValue = 0;

	var beatZ:ModifierValue = 0;
	var beatZOffset:ModifierValue = 0;
	var beatZPeriod:ModifierValue = 0;
	var beatZMult:ModifierValue = 0;

	public var beatTimes:Array<Array<Float>> = [];

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	// from troll (https://github.com/riconuts/FNF-Troll-Engine/blob/a720ab67120449dc96d2f14d20aebd0c9260e2b4/source/funkin/modchart/modifiers/BeatModifier.hx#L19)
	// however the math is simplified.
	final accelTime:Float = 0.2;
	final totalTime:Float = 0.5;
	function getBeatTime(inBeat:Float, offset:Float, mult:Float) {
		//Sys.println(mult + 1.0);
		var beat:Float = (inBeat + accelTime + offset) * (mult + 1.0);
		if (beat < 0) return 0.0;

		final endMult:Float = beat % 2 >= 1 ? -1 : 1;
		beat %= 1.0;

		if (beat >= totalTime) return 0.0;

		var amt:Float = 0.0;
		if (beat <= accelTime) {
			amt = beat / accelTime;
			amt *= amt;
		} else {
			amt = (beat - accelTime) / (totalTime - accelTime);
			amt = 1 - amt * amt;
		}

		return 40.0 * amt * endMult;
	}

	inline function cos(rads:Float, clip:Float){
		var value = Math.cos(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}


	override public function prepare(strumline:Int, beat:Float) {
		while (beatTimes.length < strumline + 1)
			beatTimes.push([0, 0, 0]);

		beatTimes[strumline][0] = getBeatTime(beat, beatOffset, beatMult);
		beatTimes[strumline][1] = getBeatTime(beat, beatYOffset, beatYMult);
		beatTimes[strumline][2] = getBeatTime(beat, beatZOffset, beatZMult);
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		// use cos so we dont need to offset pi/2
		final clip:Float = Math.abs(1 - parent.get("cosclip", strumline));

		final xPeriod = ((beatPeriod * 30) + 30);
		pos.x += this.beat * beatTimes[strumline][0] * cos(distance / xPeriod, clip);

		final yPeriod = ((beatYPeriod * 30) + 30);
		pos.y += beatY * beatTimes[strumline][1] * cos(distance / yPeriod, clip);

		final zPeriod = ((beatZPeriod * 30) + 30);
		pos.z += beatZ * beatTimes[strumline][2] * cos(distance / zPeriod, clip);
	}
}