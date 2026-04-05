package funkin.shaders;
// blame rudy for using an older flixel-addons
// https://github.com/HaxeFlixel/flixel-addons/blob/dev/flixel/addons/display/FlxRuntimeShader.hx used as reference obv

import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderParameter;
import openfl.display.ShaderInput;
import openfl.display.BitmapData;
import lime.utils.Float32Array;

using StringTools;

// for replacement since the replacement typically goes in the macro.
inline var FRAG_HEADER:String = "varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;

uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 apply_flixel_transform(vec4 color) {
	if (color.a <= 0.0 || openfl_Alphav == 0.0) return vec4(0.0);

	color.rgb /= color.a;
	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);
	return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
}

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
	vec4 color = texture2D(bitmap, coord);
	if (hasTransform) return apply_flixel_transform(color);
	else return color;
}";
inline var FRAG_BODY:String = "gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);";
inline var FRAG_DEFAULT:String = "#pragma header
void main(void) {
	#pragma body
}";

inline var VERT_HEADER:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;

attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;

uniform bool hasColorTransform;";
inline var VERT_BODY:String = "openfl_TextureCoordv = openfl_TextureCoord;

if (hasColorTransform) {
	openfl_Alphav = openfl_Alpha * colorMultiplier.a;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset / 255.0 * colorMultiplier) + (colorOffset / 255.0);
		openfl_ColorMultiplierv = openfl_ColorMultiplier * vec4(colorMultiplier.rgb, 1.0);
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(colorMultiplier.rgb, 1.0);
	}
}
else {
	openfl_Alphav = openfl_Alpha * alpha;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset + colorOffset) / 255.0;
		openfl_ColorMultiplierv = openfl_ColorMultiplier;
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(1.0);
	}
}";
inline var VERT_DEFAULT:String = "#pragma header
void main(void) {
	#pragma body
	gl_Position = openfl_Matrix * openfl_Position;
}";

class FileShader extends FlxGraphicsShader {
	public function new(frag:String, vert:String) {
		glFragmentSource = Paths.exists("shaders/" + frag + ".frag") ? Paths.getFileContent("shaders/" + frag + ".frag") : FRAG_DEFAULT;
		glFragmentSource = glFragmentSource.replace("#pragma header", FRAG_HEADER).replace("#pragma body", FRAG_BODY);

		glVertexSource = Paths.exists("shaders/" + vert + ".vert") ? Paths.getFileContent("shaders/" + vert + ".vert") : VERT_DEFAULT;
		glVertexSource = glVertexSource.replace("#pragma header", VERT_HEADER).replace("#pragma body", VERT_BODY);
		super();
	}
}