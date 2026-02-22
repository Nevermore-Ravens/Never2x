package funkin.modchart.mods;

class Swaps extends BaseModifier {
	var flip:ModifierValue = 0;
	var invert:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	override public function modifiesPosition(strumline:Int) {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		/*var newLane = lane + (1 - ((lane % 2) * 2)) * getValue(INVERT_INDEX, strumline);
		newLane += ((1.5 - newLane) * 2) * getValue(FLIP_INDEX, strumline);
		pos.x += Strumline.swagWidth * (newLane - lane);*/
		
		// vv closer to how Stepmania/ITG works
		pos.x += Strumline.swagWidth * ((lane % 2 == 0) ? 1 : -1) * invert;
		pos.x += Strumline.swagWidth * 2 * ((parent.laneCount - 1) * 0.5 - lane) * flip;
	}
}