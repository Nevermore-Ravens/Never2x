package funkin.modchart.mods;

import funkin.objects.Sustain;

class CenteredPath extends BaseModifier {
	@:alias(movepath, centered2) var centeredPath:ModifierValue = 0;
	@:alias(movepathLANE) var centeredPathLANE:ModifierValue = 0;
	var centeredPathType:ModifierValue = 0;
	var centeredPathRespectSV: ModifierValue = 0;

	var transformPath:ModifierValue = 0;
	var transformPathLANE:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = -1;
	}

	override public function modifiesDistance(strumline:Int):Bool {return true;}
	override function adjustDistance(spr:FunkinSprite, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType):Float {
		final noteSpeed:Float = field.overrideScrollSpeed <= 0 ? grandparent.scrollSpeed : field.overrideScrollSpeed;
		
		#if SV_ALLOWED
		final svMult:Float = FlxMath.lerp(1, Conductor.currentSv.multiplier, centeredPathRespectSV);
		#else
		final svMult:Float = 1;
		#end
		final mainOff = FlxMath.lerp(Strumline.swagWidth, Conductor.crotchet * svMult * 0.45 * noteSpeed, centeredPathType) * (centeredPath + centeredPathLANE);
		var distanceOffset:Float = mainOff + (transformPath + transformPathLANE);
		if(type == SUSTAIN){
			var sus: Sustain = cast spr;
			if(sus.visualEnd < sus.data.visualPosition)
				distanceOffset *= -1;
			
		}
		return distance + distanceOffset;
	}
}