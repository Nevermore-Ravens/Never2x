package funkin.modchart.mods;

class Tipsy extends BaseModifier {
	var tipsyX:ModifierValue = 0;
	var tipsyXSpeed:ModifierValue = 0;
	var tipsyXSpacing:ModifierValue = 0;
	var tipsyXOffset:ModifierValue = 0;

	var tipsy:ModifierValue = 0;
	var tipsySpeed:ModifierValue = 0;
	var tipsySpacing:ModifierValue = 0;
	var tipsyOffset:ModifierValue = 0;

	var tipsyZ:ModifierValue = 0;
	var tipsyZSpeed:ModifierValue = 0;
	var tipsyZSpacing:ModifierValue = 0;
	var tipsyZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	inline function cos(rads:Float, clip:Float){
		var value = Math.cos(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}


	// https://github.com/riconuts/FNF-Troll-Engine/blob/f6b7062b0fb759a9d08cef4205dcc157889419c3/source/funkin/modchart/modifiers/DrunkModifier.hx#L30
	inline function getTipsyVal(val:Float, speed:Float, spacing:Float, offset:Float, strumline:Int, lane:Int, time:Float, clip:Float) {
		final rads = time * ((speed * 1.2) + 1.2) + offset * 1.2 + lane * ((spacing * 1.8) + 1.8);
		return val * cos(rads, clip) * Strumline.swagWidth * 0.4;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final time = Conductor.time * 0.001;
		final clipVal:Float = Math.abs(1 - parent.get("cosclip", strumline));

		final valX = tipsyX;
		if (valX != 0.0)
			pos.x += getTipsyVal(valX, tipsyXSpeed, tipsyXSpacing, tipsyXOffset, strumline, lane, time, clipVal);

		final val = tipsy;
		if (val != 0.0)
			pos.y += getTipsyVal(val, tipsySpeed, tipsySpacing, tipsyOffset, strumline, lane, time, clipVal);

		final valZ = tipsyZ;
		if (valZ != 0.0)
			pos.z += getTipsyVal(valZ, tipsyZSpeed, tipsyZSpacing, tipsyZOffset, strumline, lane, time, clipVal);
	}
}