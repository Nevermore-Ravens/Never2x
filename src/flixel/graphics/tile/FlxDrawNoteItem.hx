package flixel.graphics.tile;

import funkin.objects.Note;
import funkin.backend.Vector3;

import openfl.Vector;
import openfl.geom.ColorTransform;
import openfl.display.BlendMode;

import flixel.math.FlxMatrix;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.tile.FlxDrawQuadsItem;

class FlxDrawNoteItem extends FlxDrawBaseItem<FlxDrawNoteItem> {
	static final stealthIdentity:Vector3 = new Vector3(1.0, 1.0, 1.0);

	public var rects:Vector<Float> = new Vector<Float>();
	public var verts:Array<Float>;
	public var stealthColor:Array<Float>;

	public function new() {
		super();
		alphas = [];
		colorOffsets = [];
		verts = [];
		stealthColor = [];
		type = NOTE;
	}

	override function reset() {
		nextTyped = null;
		next = null;

		//angles.resize(0);

		alphas.resize(0);
		colorMultipliers.resize(0);
		colorOffsets.resize(0);

		rects.length = 0;
		verts.resize(0);
		stealthColor.resize(0);
	}

	override function dispose() {
		baseDispose();

		rects = null;
		verts = null;
		stealthColor = null;
	}

	public function addVertices(frame:FlxFrame, vertices:Array<Float>, ?transform:ColorTransform, ?stealth:Float, ?alpha:Float, ?stealthCol:Vector3) {
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		verts = verts.concat(vertices);

		transform ??= FlxDrawBaseItem.colorIdentity;
		stealthCol ??= stealthIdentity;
		for (i in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD) {
			alphas.push(alpha);

			colorMultipliers.push(transform.redMultiplier);
			colorMultipliers.push(transform.greenMultiplier);
			colorMultipliers.push(transform.blueMultiplier);
			colorMultipliers.push(1);

			colorOffsets.push(transform.redOffset);
			colorOffsets.push(transform.greenOffset);
			colorOffsets.push(transform.blueOffset);
			colorOffsets.push(transform.alphaOffset);

			//stealthMix.push(i >= 2 ? stealthBot : stealthTop);
			stealthColor.push(stealthCol.x);
			stealthColor.push(stealthCol.y);
			stealthColor.push(stealthCol.z);
			stealthColor.push(stealth);
		}
	}

	override function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		verts.push(matrix.transformX(0, 0));
		verts.push(matrix.transformY(0, 0));
		verts.push(matrix.transformX(frame.frame.width, 0));
		verts.push(matrix.transformY(frame.frame.width, 0));
		verts.push(matrix.transformX(0, frame.frame.height));
		verts.push(matrix.transformY(0, frame.frame.height));
		verts.push(matrix.transformX(frame.frame.width, frame.frame.height));
		verts.push(matrix.transformY(frame.frame.width, frame.frame.height));

		transform ??= FlxDrawBaseItem.colorIdentity;
		for (i in 0...FlxDrawQuadsItem.VERTICES_PER_QUAD) {
			alphas.push(transform.alphaMultiplier);

			colorMultipliers.push(transform.redMultiplier);
			colorMultipliers.push(transform.greenMultiplier);
			colorMultipliers.push(transform.blueMultiplier);
			colorMultipliers.push(1);

			colorOffsets.push(transform.redOffset);
			colorOffsets.push(transform.greenOffset);
			colorOffsets.push(transform.blueOffset);
			colorOffsets.push(transform.alphaOffset);

			stealthColor.push(1);
			stealthColor.push(1);
			stealthColor.push(1);
			stealthColor.push(0);
		}
	}

	override function render(camera:FlxCamera):Void {
		//if (graphics.isDestroyed) throw 'Attempted to render an invalid FlxDrawNoteItem, did you destroy a cached sprite?';
		if (rects.length == 0) return;

		final shader = Note.colourShader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.wrap = wrapMode;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;

		setParameterValue(shader.canColor, colored);
		//setParameterValue(shader.hasTransform, true); // UNUSED shader parameter.

		shader.verts.value = verts;
		shader.alpha.value = alphas;
		shader.colorMultiplier.value = colorMultipliers;
		shader.colorOffset.value = colorOffsets;
		shader.stealthColor.value = stealthColor;

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.beginShaderFill(shader);
		camera.canvas.graphics.overrideDepthTest(depthCompareMode != ALWAYS, depthCompareMode);
		camera.canvas.graphics.drawQuads(rects, null, null);
		camera.canvas.graphics.endFill();
		FlxDrawBaseItem.drawCalls++;
	}

	override function get_numVertices():Int return rects.length;
	override function get_numTriangles():Int return rects.length >> 1;
}