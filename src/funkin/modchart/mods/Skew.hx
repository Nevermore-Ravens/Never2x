package funkin.modchart.mods;

class Skew extends BaseModifier {
	var skewX:ModifierValue = 0;
	var skewY:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 4;
	}

	override public function modifiesVertex(strumline:Int) {return true;}
	override public function adjustVertex(spr:FunkinSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		vertex.x -= field.centerX;
		vertex.y -= FlxG.height * 0.5;

		vertex.x += vertex.y * skewX;
		vertex.y += FlxG.height * vertex.x / (Strumline.swagWidth * 4) * skewY;

		vertex.x += field.centerX;
		vertex.y += FlxG.height * 0.5;
	}
}