package funkin.modchart.mods;

import openfl.geom.ColorTransform;
import flixel.graphics.frames.FlxFrame;
import funkin.objects.Note;

class ArrowPath extends BaseModifier {
	static var pathColor:ColorTransform = new ColorTransform();
	static var modchartPos:Vector3 = new Vector3();
	static var modchartPosLow:Vector3 = new Vector3();
	static var curStealthColor:Vector3 = new Vector3();
	static var nextStealthColor:Vector3 = new Vector3();
	public var pathFrame:FlxFrame;

	var arrowPath:ModifierValue = 0;
	var arrowPathLANE:ModifierValue = 0;

	@:alias(arrowpathgirth, arrowpathsize) var arrowPathWidth:ModifierValue = 0;
	@:alias(arrowpathgirthLANE, arrowpathsizeLANE) var arrowPathWidthLANE:ModifierValue = 0;

	var arrowPathRed:ModifierValue = 1;
	var arrowPathGreen:ModifierValue = 1;
	var arrowPathBlue:ModifierValue = 1;
	var arrowPathRedLANE:ModifierValue = 1;
	var arrowPathGreenLANE:ModifierValue = 1;
	var arrowPathBlueLANE:ModifierValue = 1;

	@:alias(arrowpathdrawsizefront) var arrowPathDrawSize:ModifierValue = 0;
	var arrowPathDrawSizeBack:ModifierValue = 0;

	var arrowPathGrain:ModifierValue = 0;
	var arrowPathStealth:ModifierValue = 1;
	@:alias(spiralarrowpath, spiralpaths) var arrowPathSpiral:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		parent.arrowPath = this;
		pathFrame = FlxG.bitmap.create(1, 1, 0xFFFFFFFF, false, "ARROW_PATH_BITMAP").imageFrame.frame;
		priority = 0;
	}

	public function drawPath(strum:StrumNote, strumline:Int, downscroll:Bool, field:Strumline) {
		if (!active[strumline]) return;

		final spiral = arrowPathSpiral == 1;
		final distInc = Math.max(20 * (arrowPathGrain + Settings.data.holdGrain), 3);
		final mult = downscroll ? -1 : 1;
		final start = -65 * (arrowPathDrawSizeBack + 1) - Strumline.swagWidth * 0.5;
		final end = FlxG.height * (arrowPathDrawSize + 1);
		final width = (1 + arrowPathWidth + arrowPathWidthLANE); // a base width of 2 but we also half it for the vertex offsetting so it cancels out.
		final stealthEffective = arrowPathStealth;
		var stealth = 0.0;
		var angleUp = 0.0;
		var angleDown = 0.0;

		// the strumline's actually at 50 but extra padding for why not.
		var dist = start;
		final newDist: Float = parent.adjustDistance(strum, dist, strum.ID, strumline, field, SUSTAIN);
		parent.scrollMult = mult;
		modchartPos.set(strum.x + strum.width * 0.5, strum.y + strum.height * 0.5 + (dist * mult), 0);
		parent.adjustPos(strum, modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);

		final perc = arrowPath + arrowPathLANE;
		var curAlpha = 0.0;
		inline function getNextPos() {
			parent.stealthColor.set(1.0, 1.0, 1.0);
			stealth = parent.getStealth(strum, newDist, dist, modchartPos, strum.ID, strumline, field, SUSTAIN) * stealthEffective;
			nextStealthColor.copyFrom(parent.stealthColor);
			
			var alpha = 
				dist < (start + distInc * 2) ?
				1.0 + (dist - (start + distInc * 2)) / (distInc * 2) :
				(dist >= (end - distInc * 2) ? 1.0 - (dist - (end - distInc * 2)) / (distInc * 2) : 1.0);
			alpha *= perc;

			dist += distInc;

			final newDist: Float = parent.adjustDistance(strum, dist, strum.ID, strumline, field, SUSTAIN);
			parent.scrollMult = mult;
			modchartPosLow.set(strum.x + strum.width * 0.5, strum.y + strum.height * 0.5 + (dist * mult), 0);
			parent.adjustPos(strum, modchartPosLow, newDist, dist, strum.ID, strumline, field, SUSTAIN);
			
			if (spiral) {
				angleDown = Math.atan2(modchartPosLow.y - modchartPos.y, modchartPosLow.x - modchartPos.x);
				angleUp += Math.abs(angleDown - angleUp) > 180 ? Math.PI * 2 : 0;
			}

			return alpha;
		}
		curAlpha = getNextPos();
		final offsetX = spiral ? width * Math.sin(angleDown) : width;
		final offsetY = spiral ? width * Math.cos(angleDown) : 0;

		Note.modchartVertices[0].set(
			modchartPos.x - offsetX,
			modchartPos.y + offsetY,
			modchartPos.z
		);
		parent.adjustVertex(strum, Note.modchartVertices[0], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
		Note.modchartVertices[0].project();
		Note.modchartVertices[1].set(
			modchartPos.x + offsetX,
			modchartPos.y - offsetY,
			modchartPos.z
		);
		parent.adjustVertex(strum, Note.modchartVertices[1], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
		Note.modchartVertices[1].project();

		pathColor.redMultiplier = arrowPathRed * arrowPathRedLANE;
		pathColor.greenMultiplier = arrowPathGreen * arrowPathGreenLANE;
		pathColor.blueMultiplier = arrowPathBlue * arrowPathBlueLANE;

		angleUp = angleDown;
		modchartPos.copyFrom(modchartPosLow);
		while (dist < end) {
			curStealthColor.copyFrom(parent.stealthColor);
			var alpha = getNextPos();
			final angle = (angleDown + angleUp) * 0.5;
			final offsetX = spiral ? width * Math.sin(angle) : width;
			final offsetY = spiral ? width * Math.cos(angle) : 0;

			Note.modchartVertices[2].set(
				modchartPos.x - offsetX,
				modchartPos.y + offsetY,
				modchartPos.z
			);
			parent.adjustVertex(strum, Note.modchartVertices[2], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
			Note.modchartVertices[2].project();
			Note.modchartVertices[3].set(
				modchartPos.x + offsetX,
				modchartPos.y - offsetY,
				modchartPos.z
			);
			parent.adjustVertex(strum, Note.modchartVertices[3], modchartPos, newDist, dist, strum.ID, strumline, field, SUSTAIN);
			Note.modchartVertices[3].project();

			pathColor.alphaMultiplier = alpha;
			parent.stealthColor.copyFrom(curStealthColor);
			parent.pushDraw(strumline, field, strum.cameras, strum.scrollFactor, pathFrame, Note.modchartVertices, pathColor, null, false, false, stealth, -1500);
			parent.stealthColor.copyFrom(nextStealthColor);

			Note.modchartVertices[0].copyFrom(Note.modchartVertices[2]);
			Note.modchartVertices[1].copyFrom(Note.modchartVertices[3]);

			angleUp = angleDown;
			modchartPos.copyFrom(modchartPosLow);
		}
	}
}