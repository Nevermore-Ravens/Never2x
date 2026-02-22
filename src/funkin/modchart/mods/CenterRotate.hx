package funkin.modchart.mods;

class CenterRotate extends BaseModifier {
	var centerRotateX:ModifierValue = 0;
	var centerRotateY:ModifierValue = 0;
	var centerRotateZ:ModifierValue = 0;

	var centerRotateXLANE:ModifierValue = 0;
	var centerRotateYLANE:ModifierValue = 0;
	var centerRotateZLANE:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 15;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		pos.x -= FlxG.width * 0.5;
		pos.y -= FlxG.height * 0.5;

		pos.rotate(
			centerRotateX + centerRotateXLANE,
			centerRotateY + centerRotateYLANE,
			centerRotateZ + centerRotateZLANE
		);

		pos.x += FlxG.width * 0.5;
		pos.y += FlxG.height * 0.5;
	}
}