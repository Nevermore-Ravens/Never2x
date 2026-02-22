package funkin.modchart.mods;

class CenterZoom extends BaseModifier {
	var centerZoom:ModifierValue = 1;
	var centerZoomX:ModifierValue = 1;
	var centerZoomY:ModifierValue = 1;
	var centerMini:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 16;
	}

	override public function modifiesPosition(strumline:Int) {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		pos.x -= FlxG.width * 0.5;
		pos.y -= FlxG.height * 0.5;

		final mainZoom = centerZoom - centerMini * 0.5;
		pos.x *= mainZoom * centerZoomX;
		pos.y *= mainZoom * centerZoomY;

		pos.x += FlxG.width * 0.5;
		pos.y += FlxG.height * 0.5;
	}

	override public function modifiesScale(strumline:Int) {return true;}
	override public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final mainZoom = centerZoom - centerMini * 0.5;
		scale.x *= mainZoom * centerZoomX;
		scale.y *= mainZoom * centerZoomY;
	}
}