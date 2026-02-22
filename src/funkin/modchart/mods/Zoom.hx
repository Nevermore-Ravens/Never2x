package funkin.modchart.mods;

class Zoom extends BaseModifier {
	var zoom:ModifierValue = 1;
	var zoomX:ModifierValue = 1;
	var zoomY:ModifierValue = 1;
	var mini:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 6;
	}

	override public function modifiesPosition(strumline:Int) {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		pos.x -= field.centerX;
		pos.y -= FlxG.height * 0.5;

		final mainZoom = zoom - mini * 0.5;
		pos.x *= mainZoom * zoomX;
		pos.y *= mainZoom * zoomY;

		pos.x += field.centerX;
		pos.y += FlxG.height * 0.5;
	}

	override public function modifiesScale(strumline:Int) {return true;}
	override public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		final mainZoom = zoom - mini * 0.5;
		scale.x *= mainZoom * zoomX;
		scale.y *= mainZoom * zoomY;
	}
}