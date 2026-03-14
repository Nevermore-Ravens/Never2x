package funkin.modchart.mods;

class SchmovinDrunk extends BaseModifier {
	var schmovinDrunk:ModifierValue = 0;
	var schmovinDrunkSpeed:ModifierValue = 0;
	var schmovinDrunkPeriod:ModifierValue = 0;
	var schmovinDrunkOffset:ModifierValue = 0;

	var schmovinDrunkY:ModifierValue = 0;
	var schmovinDrunkYSpeed:ModifierValue = 0;
	var schmovinDrunkYPeriod:ModifierValue = 0;
	var schmovinDrunkYOffset:ModifierValue = 0;

	var schmovinDrunkZ:ModifierValue = 0;
	var schmovinDrunkZSpeed:ModifierValue = 0;
	var schmovinDrunkZPeriod:ModifierValue = 0;
	var schmovinDrunkZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	inline function sin(rads:Float, clip:Float){
		var value = Math.sin(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}

	inline function getDrunkVal(val:Float, speed:Float, offset:Float, period:Float, strumline:Int, distance:Float, lane:Int, beat:Float, clipVal:Float) {
		var phaseShift = (lane * 0.5) + offset + (distance * period) / 222 * Math.PI;
		return sin((beat * speed) / 4 * Math.PI + phaseShift, clipVal) * (Strumline.swagWidth * 0.5) * val;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final clipVal:Float = Math.abs(1 - parent.get("sinclip", strumline));
		
		final val = schmovinDrunk;
		if (val != 0.0)
			pos.x += getDrunkVal(val, schmovinDrunkSpeed + 1, schmovinDrunkOffset, schmovinDrunkPeriod + 1, strumline, distance, lane, beat, clipVal);

		final valY = schmovinDrunkY;
		if (valY != 0.0)
			pos.y += getDrunkVal(valY, schmovinDrunkYSpeed + 1, schmovinDrunkYOffset, schmovinDrunkYPeriod + 1, strumline, distance, lane, beat, clipVal);

		final valZ = schmovinDrunkZ;
		if (valZ != 0.0)
			pos.z += getDrunkVal(valZ, schmovinDrunkZSpeed + 1, schmovinDrunkZOffset, schmovinDrunkZPeriod + 1, strumline, distance, lane, beat, clipVal);
	}
}