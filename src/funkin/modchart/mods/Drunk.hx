package funkin.modchart.mods;

class Drunk extends BaseModifier {
	var drunk:ModifierValue = 0;
	var drunkSpeed:ModifierValue = 0;
	var drunkSpacing:ModifierValue = 0;
	var drunkPeriod:ModifierValue = 0;
	var drunkOffset:ModifierValue = 0;

	var drunkY:ModifierValue = 0;
	var drunkYSpeed:ModifierValue = 0;
	var drunkYSpacing:ModifierValue = 0;
	var drunkYPeriod:ModifierValue = 0;
	var drunkYOffset:ModifierValue = 0;

	var drunkZ:ModifierValue = 0;
	var drunkZSpeed:ModifierValue = 0;
	var drunkZSpacing:ModifierValue = 0;
	var drunkZPeriod:ModifierValue = 0;
	var drunkZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	inline function sin(rads:Float, clip:Float){
		var value = FlxMath.fastSin(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/f6b7062b0fb759a9d08cef4205dcc157889419c3/source/funkin/modchart/modifiers/DrunkModifier.hx#L15
	inline function getDrunkVal(val:Float, speed:Float, spacing:Float, period:Float, offset:Float, strumline:Int, distance:Float, lane:Int, time:Float, clipVal:Float) {
		final rads = time * (1.0 + speed) + offset + lane * ((spacing * 0.2) + 0.2) + distance * ((period * 10.0) + 10.0) / FlxG.height;
		return val * sin(rads, clipVal) * Strumline.swagWidth * 0.5;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final time = Conductor.time * 0.001;
		final clipVal:Float = Math.abs(1 - parent.get("sinclip", strumline));

		final val = drunk;
		if (val != 0.0)
			pos.x += getDrunkVal(val, drunkSpeed, drunkSpacing, drunkPeriod, drunkOffset, strumline, distance, lane, time, clipVal);

		final valY = drunkY;
		if (valY != 0.0)
			pos.y += getDrunkVal(valY, drunkYSpeed, drunkYSpacing, drunkYPeriod, drunkYOffset, strumline, distance, lane, time, clipVal);

		final valZ = drunkZ;
		if (valZ != 0.0)
			pos.z += getDrunkVal(valZ, drunkZSpeed, drunkZSpacing, drunkZPeriod, drunkZOffset, strumline, distance, lane, time, clipVal);
	}
}