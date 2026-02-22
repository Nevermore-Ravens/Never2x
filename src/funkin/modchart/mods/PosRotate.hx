package funkin.modchart.mods;

class PosRotate extends BaseModifier {
	var rotateX:ModifierValue = 0;
	var rotateY:ModifierValue = 0;
	var rotateZ:ModifierValue = 0;

	var rotateXLANE:ModifierValue = 0;
	var rotateYLANE:ModifierValue = 0;
	var rotateZLANE:ModifierValue = 0;

	var localRotateX:ModifierValue = 0;
	var localRotateY:ModifierValue = 0;
	var localRotateZ:ModifierValue = 0;

	var localRotateXLANE:ModifierValue = 0;
	var localRotateYLANE:ModifierValue = 0;
	var localRotateZLANE:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 5;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		pos.x -= field.centerX;
		pos.y -= FlxG.height * 0.5;

		final localX = localRotateX + localRotateXLANE;
		final localY = localRotateY + localRotateYLANE;
		final localZ = localRotateZ + localRotateZLANE;
		if (localX != 0.0 || localY != 0.0 || localZ != 0.0)
			pos.rotate(localX, localY, localZ);

		final strumPos = Strumline.swagWidth * (lane - 1.5);
		pos.x -= strumPos; // technically pos.x -= (centerX + strumPos) but we already offset centerX
		// no need to offset height again.

		final normX = rotateX + rotateXLANE;
		final normY = rotateY + rotateYLANE;
		final normZ = rotateZ + rotateZLANE;
		if (normX != 0.0 || normY != 0.0 || normZ != 0.0)
			pos.rotate(normX, normY, normZ);

		pos.x += field.centerX + strumPos;
		pos.y += FlxG.height * 0.5;
	}
}