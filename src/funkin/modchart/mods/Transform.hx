package funkin.modchart.mods;

class Transform extends BaseModifier {
	var moveX:ModifierValue = 0;
	var moveY:ModifierValue = 0;
	var moveZ:ModifierValue = 0;

	var scale:ModifierValue = 1;
	var scaleX:ModifierValue = 1;
	var scaleY:ModifierValue = 1;

	var squish:ModifierValue = 0;
	var stretch:ModifierValue = 0;

	var tiny:ModifierValue = 0;
	var tinyX:ModifierValue = 0;
	var tinyY:ModifierValue = 0;

	@:alias(moverx) var moveReceptorX:ModifierValue = 0;
	@:alias(movery) var moveReceptorY:ModifierValue = 0;
	@:alias(moverz) var moveReceptorZ:ModifierValue = 0;

	var moveXLANE:ModifierValue = 0;
	var moveYLANE:ModifierValue = 0;
	var moveZLANE:ModifierValue = 0;

	var scaleLANE:ModifierValue = 1;
	var scaleXLANE:ModifierValue = 1;
	var scaleYLANE:ModifierValue = 1;

	var squishLANE:ModifierValue = 0;
	var stretchLANE:ModifierValue = 0;

	var tinyLANE:ModifierValue = 0;
	var tinyXLANE:ModifierValue = 0;
	var tinyYLANE:ModifierValue = 0;

	@:alias(moverxLANE) var moveReceptorXLANE:ModifierValue = 0;
	@:alias(moveryLANE) var moveReceptorYLANE:ModifierValue = 0;
	@:alias(moverzLANE) var moveReceptorZLANE:ModifierValue = 0;

	var moveYType:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	override public function modifiesPosition(strumline:Int):Bool {return true;}
	override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		pos.x += (moveX + moveXLANE) * Strumline.swagWidth;
		pos.y += (moveY + moveYLANE) * Strumline.swagWidth * FlxMath.lerp(1, parent.scrollMult, moveYType);
		pos.z += (moveZ + moveZLANE) * Strumline.swagWidth;
		if(type == STRUM){
			pos.x += (moveReceptorX + moveReceptorXLANE) * Strumline.swagWidth;
			pos.y += (moveReceptorY + moveReceptorYLANE) * Strumline.swagWidth;
			pos.z += (moveReceptorZ + moveReceptorZLANE) * Strumline.swagWidth;
		}
	}

	override public function modifiesScale(strumline:Int) {return true;}
	override public function adjustScale(spr:FunkinSprite, scale:FlxPoint, distance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		var mainScale = this.scale * scaleLANE;
		mainScale *= Math.pow(0.5, tiny + tinyLANE);

		final stretch = stretch + stretchLANE;
		final squish = squish + squishLANE;

		var scaleX = mainScale * scaleX * scaleXLANE;
		scaleX *= Math.pow(0.5, tinyX + tinyXLANE);
		scaleX *= FlxMath.lerp(1, 0.5, stretch);
		scaleX *= FlxMath.lerp(1, 2, squish);

		var scaleY = mainScale * scaleY * scaleYLANE;
		scaleY *= Math.pow(0.5, tinyY + tinyYLANE);
		scaleY *= FlxMath.lerp(1, 2, stretch);
		scaleY *= FlxMath.lerp(1, 0.5, squish);

		scale.x *= scaleX;
		scale.y *= scaleY;
	}
}