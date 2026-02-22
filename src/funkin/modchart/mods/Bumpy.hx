package funkin.modchart.mods;

class Bumpy extends BaseModifier {
	var bumpyX:ModifierValue = 0;
	var bumpyXOffset:ModifierValue = 0;
	var bumpyXPeriod:ModifierValue = 0;

	var bumpyY:ModifierValue = 0;
	var bumpyYOffset:ModifierValue = 0;
	var bumpyYPeriod:ModifierValue = 0;

	var bumpy:ModifierValue = 0;
	var bumpyOffset:ModifierValue = 0;
	var bumpyPeriod:ModifierValue = 0;

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


	// https://github.com/riconuts/FNF-Troll-Engine/blob/f6b7062b0fb759a9d08cef4205dcc157889419c3/source/funkin/modchart/modifiers/DrunkModifier.hx#L45
	inline function getBumpyVal(val:Float, offset:Float, period:Float, strumline:Int, distance:Float, lane:Int, clip:Float) {
		final rads = (distance + (100.0 * offset)) / ((period * 24.0) + 24.0);
		return val * sin(rads, clip) * 40.0;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final clipVal:Float = Math.abs(1 - parent.get("sinclip", strumline));

		final valX = bumpyX;
		if (valX != 0.0)
			pos.x += getBumpyVal(valX, bumpyXOffset, bumpyXPeriod, strumline, distance, lane, clipVal);

		final valY = bumpyY;
		if (valY != 0.0)
			pos.y += getBumpyVal(valY, bumpyYOffset, bumpyYPeriod, strumline, distance, lane, clipVal);

		final val = bumpy;
		if (val != 0.0)
			pos.z += getBumpyVal(val, bumpyOffset, bumpyPeriod, strumline, distance, lane, clipVal);
	}
}