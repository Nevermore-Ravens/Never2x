package funkin.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

/**
 * A custom coloring method, mainly for quants.
 * 
 * Grayscales then turns Black-Gray-White to Black-(INPUT-COLOR)-White.
 */
class NoteShader extends FlxGraphicsShader {
	@:glVertexSource("#pragma header

	attribute vec2 verts;
	attribute vec4 stealthColor;

	varying vec4 stealthCol;

	void main() {
		openfl_TextureCoordv = openfl_TextureCoord;
		gl_Position = openfl_Matrix * vec4(verts, 0.0, 1.0);

		openfl_Alphav = openfl_Alpha * alpha * colorMultiplier.a * min(2.0 - stealthColor.a * 2.0, 1.0);
		if (openfl_HasColorTransform) {
			openfl_ColorMultiplierv = openfl_ColorMultiplier * vec4(colorMultiplier.rgb, 1.0);
			openfl_ColorOffsetv = (openfl_ColorOffset / 255.0 * colorMultiplier) + (colorOffset / 255.0);
		}
		else {
			openfl_ColorMultiplierv = vec4(colorMultiplier.rgb, 1.0);
			openfl_ColorOffsetv = colorOffset / 255.0;
		}
		
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = colorMultiplier;

		stealthCol = vec4(stealthColor.rgb, max(min(stealthColor.a * 2.0, 1.0), 0.0));
	}")
	@:glFragmentSource("#pragma header
	varying vec4 stealthCol;
	uniform bool canColor;

	void main() {
		vec4 color = texture2D(bitmap, openfl_TextureCoordv);
		if (color.a == 0.0 || openfl_Alphav == 0.0) discard;

		color.rgb /= color.a;
		if (canColor) {
			float high = max(max(color.r, color.g), color.b);
			float low = min(min(color.r, color.g), color.b);
			float gray = high + low;
			if (gray > 1.0) color = vec4(mix(openfl_ColorMultiplierv.rgb, vec3(1.0), gray - 1.0), color.a);
			else color = vec4(openfl_ColorMultiplierv.rgb * gray, color.a);

			color = clamp(openfl_ColorOffsetv + color, 0.0, 1.0);
		}
		else {
			color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);
		}

		color.rgb = mix(color.rgb, stealthCol.rgb, stealthCol.a);
		gl_FragColor = vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}")

	// just in case
	public function new() {
		super();
	}
}