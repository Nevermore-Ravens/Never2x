package funkin.modchart.mods;

import flixel.math.FlxAngle;
import funkin.objects.Note;

class Confusion extends BaseModifier {
	var confusionX:ModifierValue = 0;
	var confusionY:ModifierValue = 0;
	var confusion:ModifierValue = 0;

	var confusionXLANE:ModifierValue = 0;
	var confusionYLANE:ModifierValue = 0;
	var confusionLANE:ModifierValue = 0;
	
	var confusionOffsetX:ModifierValue = 0;
	var confusionOffsetY:ModifierValue = 0;
	var confusionOffset:ModifierValue = 0;

	var confusionOffsetXLANE:ModifierValue = 0;
	var confusionOffsetYLANE:ModifierValue = 0;
	var confusionOffsetLANE:ModifierValue = 0;

	var roll:ModifierValue = 0;
	var twirl:ModifierValue = 0;
	var dizzy:ModifierValue = 0;
	var dizzyHolds:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = -1;
	}

	override public function modifiesVertex(strumline:Int) {return true;}
	override public function adjustVertex(spr:FunkinSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		vertex.x -= pos.x;
		vertex.y -= pos.y;
		vertex.z -= pos.z;

		var dizzyX:Float = 0;
		var dizzyY:Float = 0;
		var dizzyZ:Float = 0;
		if(type != STRUM && spr is Note){
			var note: Note = cast spr;
			if(note.data.length == 0 && type == NOTE)
				dizzyX = distance * 0.5 * roll;

			dizzyY = distance * 0.5 * twirl;
			
			if((note.data.length == 0 || dizzyHolds == 1)  && type == NOTE)
				dizzyZ = (note.data.beat - beat) * dizzy * FlxAngle.TO_DEG;
			dizzyX %= 360;
			dizzyY %= 360;
			dizzyZ %= 360;
		}

		if (type == SUSTAIN){
			vertex.rotate(
				dizzyX,
				dizzyY,
				dizzyZ
			);
		}else{
			vertex.rotate(
				(confusionX + confusionXLANE) * beat + (confusionOffsetX + confusionOffsetXLANE) + dizzyX,
				(confusionY + confusionYLANE) * beat + (confusionOffsetY + confusionOffsetYLANE) + dizzyY,
				(confusion + confusionLANE) * beat + (confusionOffset + confusionOffsetLANE) + dizzyZ
			);
		}

		vertex.x += pos.x;
		vertex.y += pos.y;
		vertex.z += pos.z;
	}
}