package funkin.modchart.mods;

class OpponentSwap extends BaseModifier {
	var opponentSwap:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 10;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		pos.x += ((FlxG.width - field.centerX) - field.centerX) * opponentSwap;
	}
}