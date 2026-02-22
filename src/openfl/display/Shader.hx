package openfl.display;

import openfl.display3D.Context3DWrapMode;
import openfl.display3D.Context3DMipFilter;
import openfl.display3D.Context3DTextureFilter;
#if !flash
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.display._internal.ShaderBuffer;
import openfl.utils._internal.Float32Array;
import openfl.utils._internal.Log;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.utils.ByteArray;
import openfl.Lib;

typedef ShaderExtension = {name:String, behavior:String};

// storageType -> type -> typeName -> Name -> ArrayLen -> ArrayLenString -> Default Variable
typedef ShaderProcessCallback = String->ShaderParameterType->String->String->Int->String->Dynamic->String;

/**
	// TODO: Document GLSL Shaders
	A Shader instance represents a Pixel Bender shader kernel in ActionScript.
	To use a shader in your application, you create a Shader instance for it.
	You then use that Shader instance in the appropriate way according to the
	effect you want to create. For example, to use the shader as a filter, you
	assign the Shader instance to the `shader` property of a ShaderFilter
	object.
	A shader defines a function that executes on all the pixels in an image,
	one pixel at a time. The result of each call to the function is the output
	color at that pixel coordinate in the image. A shader can specify one or
	more input images, which are images whose content can be used in
	determining the output of the function. A shader can also specify one or
	more parameters, which are input values that can be used in calculating
	the function output. In a single shader execution, the input and parameter
	values are constant. The only thing that varies is the coordinate of the
	pixel whose color is the function result. Shader function calls for
	multiple output pixel coordinates execute in parallel to improve shader
	execution performance.

	The shader bytecode can be loaded at run time using a URLLoader instance.
	The following example demonstrates loading a shader bytecode file at run
	time and linking it to a Shader instance.

	```as3
	var loader:URLLoader = new URLLoader();
	loader.dataFormat = URLLoaderDataFormat.BINARY;
	loader.addEventListener(Event.COMPLETE, onLoadComplete);
	loader.load(new URLRequest("myShader.pbj"));
	var shader:Shader;

	function onLoadComplete(event:Event):void {
		// Create a new shader and set the loaded data as its bytecode
		shader = new Shader();
		shader.byteCode = loader.data;

		// You can also pass the bytecode to the Shader() constructor like this:
		// shader = new Shader(loader.data);

		// do something with the shader
	}
	```

	You can also embed the shader into the SWF at compile time using the
	`[Embed]` metadata tag. The `[Embed]` metadata tag is only available if
	you use the Flex SDK to compile the SWF. The `[Embed]` tag's `source`
	parameter points to the shader file, and its `mimeType` parameter is
	`"application/octet-stream"`, as in this example:

	```as3
	[Embed(source="myShader.pbj", mimeType="application/octet-stream)] var MyShaderClass:Class;

	// ...

	// create a new shader and set the embedded shader as its bytecode var
	shaderShader = new Shader();
	shader.byteCode = new MyShaderClass();

	// You can also pass the bytecode to the Shader() constructor like this:
	// var shader:Shader = new Shader(new MyShaderClass());

	// do something with the shader
	```

	In either case, you link the raw shader (the `URLLoader.data` property or
	an instance of the `[Embed]` data class) to the Shader instance. As the
	previous examples demonstrate, you can do this in two ways. You can pass
	the shader bytecode as an argument to the `Shader()` constructor.
	Alternatively, you can set it as the Shader instance's `byteCode`
	property.

	Once a Shader instance is created, it can be used in one of several ways:

	* A shader fill: The output of the shader is used as a fill for content
	drawn with the drawing API. Pass the Shader instance as an argument to the
	`Graphics.beginShaderFill()` method.
	* A shader filter: The output of the shader is used as a graphic filter
	applied to a display object. Assign the Shader instance to the `shader`
	property of a ShaderFilter instance.
	* A blend mode: The output of the shader is rendered as the blending
	between two overlapping display objects. Assign the Shader instance to the
	`blendShader` property of the upper of the two display objects.
	* Background shader processing: The shader executes in the background,
	avoiding the possibility of freezing the display, and dispatches an event
	when processing is complete. Assign the Shader instance to the `shader`
	property of a ShaderJob instance.

	Shader fills, filters, and blends are not supported under GPU rendering.

	**Mobile Browser Support:** This feature is not supported in mobile
	browsers.

	_Adobe AIR profile support:_ This feature is supported on all desktop operating
	systems, but it is not supported on all mobile devices. It is not
	supported on AIR for TV devices. See
	[AIR Profile Support](https://help.adobe.com/en_US/air/build/WS144092a96ffef7cc16ddeea2126bb46b82f-8000.html)
	for more information regarding API support across multiple profiles.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
@:access(openfl.display.Stage)
@:access(openfl.events.UncaughtErrorEvents)
#if !macro
@:autoBuild(openfl.display._internal.ShaderMacro.build())
#end
class Shader
{
	public static inline function getDefaultGLVersion():String
	{
		// Specify the default glVersion.
		// We can use compile defines to guess the value that prevents crashes in the majority of cases.
		return #if mac "410" #else "300 es" #end;
		//return #if (android) "100" #elseif (web) "100" #elseif (mac) "120" #elseif (desktop) "150" #else "100" #end;
	}

	private static inline var fragColorHeaderFix:String =
		#if desktop
		"layout(location = 0) out vec4 fragColor;\n"
		#else
		"out vec4 fragColor;\n"
		#end;

	public static function getGLSLTextVersion(source:String, ?defaultGLVersion:String):String
	{
		var idx = source.indexOf("#version ");
		if (idx == -1) return defaultGLVersion ?? getDefaultGLVersion();

		var idx2 = source.indexOf('\n', idx + 9);
		return StringTools.trim(source.substring(idx + 9, idx2 == -1 ? source.length : idx2));
	}

	/**
	 * Attempt to migrate GLSL code from the current (old) GLSL shader format to the specified (newer) one.
	 * @param source The source to convert.
	 * @param version The version to convert to.
	 * @param isFragment Whether the source is a fragment shader. False if it is a vertex shader.
	 * @return The converted source.
	 */
	public static function processGLSLText(source:String, glVersion:String, isFragment:Bool, ?pragmas:Map<String, String>):String
	{
		if (glVersion == "" || glVersion == null) glVersion = getDefaultGLVersion();
		if (StringTools.endsWith(glVersion, " core")) glVersion = StringTools.replace(glVersion, " core", "");

		var versionIdx = source.indexOf("#version ");
		if (versionIdx != -1) {
			var idx2 = source.indexOf('\n', versionIdx + 9);
			source = source.substring(0, versionIdx) + source.substr(idx2);
		}

		var injectedFragColor = StringTools.contains(source, "out vec4"), canInjectFragColorFix = switch (glVersion) {
			case "300 es", "330", "400", "410", "420", "430", "440", "450", "460": isFragment;
			default: false;
		};
		if (pragmas != null) {
			var pragmaKeyword:EReg = ~/#pragma (\w+)/g;
			source = pragmaKeyword.map(source, (_) -> {
				var name = pragmaKeyword.matched(1);
				var pragma = pragmas.exists(name) ? pragmas.get(name) : "";
				if (canInjectFragColorFix && !injectedFragColor && name == "header" && !StringTools.contains(pragma, "out vec4")) {
					injectedFragColor = true;
					return fragColorHeaderFix + pragma;
				}
				return pragma;
			});
		}

		if (canInjectFragColorFix && !injectedFragColor) source = fragColorHeaderFix + source;

		if (StringTools.endsWith(glVersion, " compatibility")) return source;

		// Recall: Attribute values are per-vertex, varying values are per-fragment
		// Thus, an `out` value in the vertex shader is an `in` value in the fragment shader
		var attributeKeyword:EReg = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/g; // g to match all
		var varyingKeyword:EReg = ~/varying ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/g; // g to match all

		var texture2DKeyword:EReg = ~/texture2D/g;
		var glFragColorKeyword:EReg = ~/gl_FragColor/g;

		switch (glVersion) {
			default:
				// Don't make any changes to undefined versions.
				return source;

			case "100", "110", "120", "130", "140", "150":
				return source;

			case "300 es":
				var result = source;
				// Migrate, replacing "attribute" with "in" and "varying" with "out".
				if (isFragment)
				{
					result = varyingKeyword.replace(result, "in $1 $2");
				}
				else
				{
					result = attributeKeyword.replace(result, "in $1 $2");
					result = varyingKeyword.replace(result, "out $1 $2");
				}
				result = texture2DKeyword.replace(result, "texture");
				result = glFragColorKeyword.replace(result, "fragColor");
				return result;

			case "310 es", "320 es":
				return processGLSLText(source, "300 es", isFragment);

			case "330":
				#if desktop
				return processGLSLText(source, "300 es", isFragment);
				#else
				return glFragColorKeyword.replace(result, "fragColor");
				#end

			case "400", "410", "420", "430", "440", "450", "460":
				return processGLSLText(source, "330", isFragment);
		}
	}

	private static function buildGLSLExtensions(glExtensions:Array<ShaderExtension>, glVersion:String,
			isFragment:Bool):Array<ShaderExtension>
	{
		if (glVersion == "" || glVersion == null || StringTools.endsWith(glVersion, " compatibility")) return glExtensions;
		if (StringTools.endsWith(glVersion, " core")) return buildGLSLExtensions(glExtensions, StringTools.replace(glVersion, " core", ""), isFragment);

		switch (glVersion)
		{
			// Don't add any extensions to undefined versions
			default:
				return glExtensions;

			case "150", "300 es", "310 es", "320 es", "330":
				var hasSeparateShaderObjects = false;
				var hasSampleShading = false;
				for (extension in glExtensions)
				{
					switch (extension.name)
					{
						case "GL_EXT_separate_shader_objects": hasSeparateShaderObjects = true;
						case "GL_ARB_separate_shader_objects": hasSeparateShaderObjects = true;
						case "GL_ARB_sample_shading": hasSampleShading = true;
					}
				}

				#if desktop
				if (!hasSeparateShaderObjects)
				{
					#if linux
					glExtensions.push({name: "GL_EXT_separate_shader_objects", behavior: "require"});
					#else
					glExtensions.push({name: "GL_ARB_separate_shader_objects", behavior: "require"});
					#end
				}
				#end

				if (!hasSampleShading)
				{
					glExtensions.push({name: "GL_ARB_sample_shading", behavior: "enable"});
				}

				return glExtensions;

			case "400", "410", "420", "430", "440", "450", "460":
				var hasSampleShading = false;
				for (extension in glExtensions)
				{
					switch (extension.name)
					{
						case "GL_ARB_sample_shading": hasSampleShading = true;
					}
				}

				if (!hasSampleShading)
				{
					glExtensions.push({name: "GL_ARB_sample_shading", behavior: "enable"});
				}

				return glExtensions;
		}
	}

	private static function processGLSLData(source:String, storageType:String, callback:ShaderProcessCallback):String
	{
		var regex, defaultValue:Dynamic, type:ShaderParameterType, arrLength:Null<Int>;
		var isUniform = storageType == "uniform", lastMatch = 0, position;

		if (isUniform) regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)(?:\[(\w+)\])?\s*(?:=)?\s*(.+?(?=;))?/g;
		else if (storageType == "in") regex = ~/in ([A-Za-z0-9]+) ([A-Za-z0-9_]+)(?:\[(\w+)\])?/g;
		else regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)(?:\[(\w+)\])?/g;

		return regex.map(source, (_) -> {
			if (regex.matched(3) == null) arrLength = 0;
			else if ((arrLength = Std.parseInt(regex.matched(3))) == null) arrLength = 1;

			type = Program3D.getParameterTypeFromGLString(regex.matched(1), arrLength + 1);

			//defaultValue = regex.matched(4);
			//if (defaultValue) 

			// TODO: Implement default value
			return callback(storageType, type, regex.matched(1), regex.matched(2), arrLength < 1 ? 1 : arrLength, regex.matched(3), null);
		});
	}

	/**
		The raw shader bytecode for this Shader instance.
	**/
	public var byteCode(null, default):ByteArray;

	/**
		Provides access to parameters, input images, and metadata for the
		Shader instance. ShaderParameter objects representing parameters for
		the shader, ShaderInput objects representing the input images for the
		shader, and other values representing the shader's metadata are
		dynamically added as properties of the `data` property object when the
		Shader instance is created. Those properties can be used to introspect
		the shader and to set parameter and input values.
		For information about accessing and manipulating the dynamic
		properties of the `data` object, see the ShaderData class description.
	**/
	public var data(get, set):ShaderData;

	/**
		Get or set the GLSL version used in the header when compiling with GLSL.

		@default The default value is determined at compile time.
	**/
	public var glVersion(get, set):String;

	/**
		The raw of this GLSL Version used before being applied to compile with GLSL.
	**/
	public var glVersionRaw(get, never):Null<String>;


	/**
		Provides additional `#extension` directives to insert in the vertex shaders.

		Example:
		```
		@:glVertexExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		// or @:glExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		```
	**/
	public var glVertexExtensions(get, set):Array<ShaderExtension>;

	/**
		Provides additional `#extension` directives to insert in the fragment shaders.

		Example:
		```
		@:glFragmentExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		// or @:glExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		```
	**/
	public var glFragmentExtensions(get, set):Array<ShaderExtension>;

	/**
		Provides an additional pragmas to use in (child class of) vertex shaders.

		Example:
		```
		@:glVertexHeader(...)
		@:glVertexBody(...)
		```
	**/
	public var glVertexPragmas(get, set):Map<String, String>;

	/**
		Provides an additional pragmas to use in (child class of) fragment shaders.

		Example:
		```
		@:glFragmentHeader(...)
		@:glFragmentBody(...)
		```
	**/
	public var glFragmentPragmas(get, set):Map<String, String>;

	/**
		The default GLSL vertex header, before being applied to the vertex source.
	**/
	public var glFragmentHeaderRaw(get, never):String;

	/**
		The default GLSL vertex body, before being applied to the vertex source.
	**/
	public var glFragmentBodyRaw(get, never):String;

	/**
		The default GLSL fragment source, before `#pragma` values are replaced.
	**/
	public var glFragmentSourceRaw(get, never):String;

	/**
		Get or set the fragment source used when compiling with GLSL.

		This property is not available on the Flash target.
	**/
	public var glFragmentSource(get, set):String;

	/**
		The compiled GLProgram if available.

		This property is not available on the Flash target.
	**/
	@SuppressWarnings("checkstyle:Dynamic") public var glProgram(default, null):GLProgram;

	/**
		The default GLSL vertex header, before being applied to the vertex source.
	**/
	public var glVertexHeaderRaw(get, never):String;

	/**
		The default GLSL vertex body, before being applied to the vertex source.
	**/
	public var glVertexBodyRaw(get, never):String;

	/**
		The default GLSL vertex source, before `#pragma` values are replaced.
	**/
	public var glVertexSourceRaw(get, never):String;

	/**
		Get or set the vertex source used when compiling with GLSL.

		This property is not available on the Flash target.
	**/
	public var glVertexSource(get, set):String;

	/**
		The precision of math operations performed by the shader.
		The set of possible values for the `precisionHint` property is defined
		by the constants in the ShaderPrecision class.

		The default value is `ShaderPrecision.FULL`. Setting the precision to
		`ShaderPrecision.FAST` can speed up math operations at the expense of
		precision.

		Full precision mode (`ShaderPrecision.FULL`) computes all math
		operations to the full width of the IEEE 32-bit floating standard and
		provides consistent behavior on all platforms. In this mode, some math
		operations such as trigonometric and exponential functions can be
		slow.

		Fast precision mode (`ShaderPrecision.FAST`) is designed for maximum
		performance but does not work consistently on different platforms and
		individual CPU configurations. In many cases, this level of precision
		is sufficient to create graphic effects without visible artifacts.

		The precision mode selection affects the following shader operations.
		These operations are faster on an Intel processor with the SSE
		instruction set:

		* `sin(x)`
		* `cos(x)`
		* `tan(x)`
		* `asin(x)`
		* `acos(x)`
		* `atan(x)`
		* `atan(x, y)`
		* `exp(x)`
		* `exp2(x)`
		* `log(x)`
		* `log2(x)`
		* `pow(x, y)`
		* `reciprocal(x)`
		* `sqrt(x)`
	**/
	public var precisionHint:ShaderPrecision;

	/**
		The compiled Program3D if available.

		This property is not available on the Flash target.
	**/
	public var program:Program3D;

	@:noCompletion private var __alpha:ShaderParameter<Float>;
	@:noCompletion private var __bitmap:ShaderInput<BitmapData>;
	@:noCompletion private var __colorMultiplier:ShaderParameter<Float>;
	@:noCompletion private var __colorOffset:ShaderParameter<Float>;
	@:noCompletion private var __context:Context3D;
	@:noCompletion private var __data:ShaderData;
	@:noCompletion private var __glVertexExtensions:Array<ShaderExtension>;
	@:noCompletion private var __glFragmentExtensions:Array<ShaderExtension>;
	@:noCompletion private var __glVertexPragmas:Map<String, String>;
	@:noCompletion private var __glFragmentPragmas:Map<String, String>;
	@:noCompletion private var __glVersionRaw:String;
	@:noCompletion private var __glVersion:String;
	@:noCompletion private var __glFragmentSourceRaw:String;
	@:noCompletion private var __glFragmentSource:String;
	@:noCompletion private var __glSourceDirty:Bool;
	@:noCompletion private var __glVertexSourceRaw:String;
	@:noCompletion private var __glVertexSource:String;
	@:noCompletion private var __hasColorTransform:ShaderParameter<Bool>;
	@:noCompletion private var __inputBitmapData:Array<ShaderInput<BitmapData>>;
	@:noCompletion private var __isGenerated:Bool;
	@:noCompletion private var __matrix:ShaderParameter<Float>;
	@:noCompletion private var __numPasses:Int;
	@:noCompletion private var __paramBool:Array<ShaderParameter<Bool>>;
	@:noCompletion private var __paramFloat:Array<ShaderParameter<Float>>;
	@:noCompletion private var __paramInt:Array<ShaderParameter<Int>>;
	@:noCompletion private var __position:ShaderParameter<Float>;
	@:noCompletion private var __textureCoord:ShaderParameter<Float>;
	@:noCompletion private var __texture:ShaderInput<BitmapData>;
	@:noCompletion private var __textureSize:ShaderParameter<Float>;

	#if openfljs
	@:noCompletion private static function __init__()
	{
		untyped Object.defineProperties(Shader.prototype, {
			"data": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_data (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_data (v); }")
			},
			"glVertexExtensions": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexExtensions (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVertexExtensions (v); }")
			},
			"glFragmentExtensions": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentExtensions (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glFragmentExtensions (v); }")
			},
			"glVersion": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVersion (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVersion (v); }")
			},
			"glFragmentHeaderRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentHeaderRaw (); }"),
			},
			"glFragmentBodyRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentBodyRaw (); }"),
			},
			"glFragmentSourceRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentSourceRaw (); }"),
			},
			"glFragmentSource": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentSource (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glFragmentSource (v); }")
			},
			"glVertexHeaderRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexHeaderRaw (); }"),
			},
			"glVertexBodyRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexBodyRaw (); }"),
			},
			"glVertexSourceRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexSourceRaw (); }"),
			},
			"glVertexSource": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexSource (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVertexSource (v); }")
			},
		});
	}
	#end

	/**
		Creates a new Shader instance.

		@param code The raw shader bytecode to link to the Shader.
	**/
	public function new(code:ByteArray = null)
	{
		byteCode = code;
		precisionHint = FULL;

		__glSourceDirty = true;
		__numPasses = 1;
		__data = new ShaderData(code);
	}

	@:noCompletion private function __clearUseArray():Void
	{
		for (parameter in __paramBool)
		{
			parameter.__useArray = false;
		}

		for (parameter in __paramFloat)
		{
			parameter.__useArray = false;
		}

		for (parameter in __paramInt)
		{
			parameter.__useArray = false;
		}
	}

	// private function __clone ():Shader {
	// var classType = Type.getClass (this);
	// var shader = Type.createInstance (classType, []);
	// for (input in __inputBitmapData) {
	// 	if (input.input != null) {
	// 		var field = Reflect.field (shader.data, input.name);
	// 		field.channels = input.channels;
	// 		field.height = input.height;
	// 		field.input = input.input;
	// 		field.smoothing = input.smoothing;
	// 		field.width = input.width;
	// 	}
	// }
	// for (param in __paramBool) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// for (param in __paramFloat) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// for (param in __paramInt) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// return shader;
	// }

	@:noCompletion private function __disable():Void
	{
		if (program != null)
		{
			__disableGL();
		}
	}

	@:noCompletion private function __disableGL():Void
	{
		var gl = __context.gl;

		var textureCount = 0;

		for (input in __inputBitmapData)
		{
			input.__disableGL(__context, textureCount);
			textureCount++;
			if (textureCount == gl.MAX_TEXTURE_IMAGE_UNITS) break;
		}

		for (parameter in __paramBool)
		{
			parameter.__disableGL(__context);
		}

		for (parameter in __paramFloat)
		{
			parameter.__disableGL(__context);
		}

		for (parameter in __paramInt)
		{
			parameter.__disableGL(__context);
		}

		__context.__bindGLArrayBuffer(null);

		#if lime
		if (__context.__context.type == OPENGL)
		{
			gl.disable(gl.TEXTURE_2D);
		}
		#end
	}

	@:noCompletion private function __enable():Void
	{
		__init();

		if (program != null)
		{
			__enableGL();
		}
	}

	@:noCompletion private function __enableGL():Void
	{
		var textureCount = 0;

		var gl = __context.gl;

		for (input in __inputBitmapData)
		{
			gl.uniform1i(input.index, textureCount);
			textureCount++;
		}

		#if lime
		if (__context.__context.type == OPENGL && textureCount > 0)
		{
			gl.enable(gl.TEXTURE_2D);
		}
		#end
	}

	@:noCompletion private function __resetParams():Void
	{
		#if haxe4
		if (__inputBitmapData == null) __inputBitmapData = new Array(); else __inputBitmapData.resize(0);
		if (__paramBool == null) __paramBool = new Array(); else __paramBool.resize(0);
		if (__paramFloat == null) __paramFloat = new Array(); else __paramFloat.resize(0);
		if (__paramInt == null) __paramInt = new Array(); else __paramInt.resize(0);
		#else
		__inputBitmapData = new Array();
		__paramBool = new Array();
		__paramFloat = new Array();
		__paramInt = new Array();
		#end
	}

	@:noCompletion private function __init():Void
	{
		if (__data == null)
		{
			__data = cast new ShaderData(null);
		}

		if (__glFragmentSource != null && __glVertexSource != null && (program == null || __glSourceDirty))
		{
			if (__context != null)
			{
				__initGL();
			}
			else if (__glSourceDirty) {
				__glSourceDirty = false;
				__resetParams();
				if (Lib.current.stage != null && Lib.current.stage.context3D != null) {
					var vertex = __buildSourcePrefix(false) + __glVertexSource;
					var fragment = __buildSourcePrefix(true) + __glFragmentSource;
					var id = vertex + fragment;
					if (Lib.current.stage.context3D.__programs.exists(id))
					{
						program = (__context = Lib.current.stage.context3D).__programs.get(id);
						__buildParamData();
						return;
					}
				}

				program = null;
				__processGLData(__glVertexSource, "attribute");
				__processGLData(__glVertexSource, "in");
				__processGLData(__glVertexSource, "uniform");
				__processGLData(__glFragmentSource, "uniform");
			}
		}
	}

	@:noCompletion private function __buildSourcePrefix(isFragment:Bool):String
	{
		var result = "";

		var ver = StringTools.replace(StringTools.replace(__glVersion, " core", ""), " compatibility", "");
		var canInjectBlendAdvancedExt = OpenGLRenderer.__complexBlendsSupported && isFragment && 
			(!StringTools.startsWith(__glVersion, "1") || __glVersion == "150");

		if (canInjectBlendAdvancedExt) result += "#extension GL_KHR_blend_equation_advanced : enable\n";

		var extList = buildGLSLExtensions(isFragment ? __glFragmentExtensions : __glVertexExtensions, __glVersion, isFragment);
		for (ext in extList)
		{
			result += "#extension " + ext.name + " : " + ext.behavior + "\n";
		}

		// #version must be the first directive and cannot be repeated,
		// while #extension directives must be before any non-preprocessor tokens.

		result += "\n#ifdef GL_ES\n" + (
			precisionHint == FULL ?
			"#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif\n" :
			"precision lowp float;\n"
		) + "#endif\n";
		if (__glVersion != null && __glVersion != "") result = "#version " + __glVersion + "\n" + result;

		if (canInjectBlendAdvancedExt) result += "#ifdef GL_KHR_blend_equation_advanced\nlayout(blend_support_all_equations) out;\n#endif\n";

		return result;
	}

	@:noCompletion private function __initGL():Void
	{
		if (__context == null || !__glSourceDirty && program != null) return;

		var vertex = __buildSourcePrefix(false) + __glVertexSource;
		var fragment = __buildSourcePrefix(true) + __glFragmentSource;
		var id = vertex + fragment;

		if (__context.__programs.exists(id))
		{
			program = __context.__programs.get(id);
		}
		else
		{
			program = __context.createProgram(GLSL);
			if (openfl.Lib.current.stage.__uncaughtErrorEvents.__enabled)
			{
				try
				{
					program.uploadSources(vertex, fragment);
					__context.__programs.set(id, program);
				}
				catch (e:Dynamic)
				{
					openfl.Lib.current.stage.__handleError(e);
				}
			}
			else
			{
				program.uploadSources(vertex, fragment);
				__context.__programs.set(id, program);
			}
		}

		__resetParams();
		__buildParamData();
		__glSourceDirty = false;
	}

	@:noCompletion private function __processGLData(source:String, storageType:String):Void
	{
		processGLSLData(source, storageType, (storageType:String, type:ShaderParameterType,
			typeName:String, name:String, arrLength:Int, arrString:String, defaultValue:Dynamic) ->
		{
			if (StringTools.startsWith(name, "gl_") || StringTools.startsWith(name, "ofl_"))
			{
				return "";
			}
			__registerParameter(name, type, arrLength, -1, storageType == "uniform", StringTools.startsWith(typeName, "sampler"), defaultValue);
			return "";
		});
	}

	@:noCompletion private function __buildParamData():Void
	{
		var name:String;
		for (i in 0...program.__glslAttribNames.length)
		{
			name = program.__glslAttribNames[i];
			if (StringTools.startsWith(name, "gl_") || StringTools.startsWith(name, "ofl_"))
			{
				continue;
			}

			__registerParameter(name, program.__glslAttribTypes[i], program.__glslAttribSizes[i], program.__glslAttribLocations[i], false, false, null);
		}

		for (i in 0...program.__glslSamplerNames.length)
		{
			__registerParameter(program.__glslSamplerNames[i], BOOL, 1, program.__glslSamplerLocations[i], true, true, program.__glslUniformDefaults[i]);
		}

		for (i in 0...program.__glslUniformNames.length)
		{
			name = program.__glslUniformNames[i];
			if (StringTools.startsWith(name, "gl_") || StringTools.startsWith(name, "ofl_"))
			{
				continue;
			}

			__registerParameter(name, program.__glslUniformTypes[i], program.__glslUniformSizes[i], program.__glslUniformLocations[i], true, false, program.__glslUniformDefaults[i]);
		}
	}

	@:noCompletion private function __registerParameter(name:String, type:ShaderParameterType, size:Int, location:Int,
		isUniform:Bool, isSampler:Bool, defaultValue:Dynamic)
	{
		var arrayLength = switch (type)
		{
			case MATRIX2X2, MATRIX2X3, MATRIX2X4: 2;
			case MATRIX3X3, MATRIX3X2, MATRIX3X4: 3;
			case MATRIX4X4, MATRIX4X2, MATRIX4X3: 4;
			default: size;
		}

		var length = switch (type)
		{
			case BOOL2, BOOL2V, INT2, INT2V, FLOAT2, FLOAT2V, MATRIX2X2: 2;
			case BOOL3, BOOL3V, INT3, INT3V, FLOAT3, FLOAT3V, MATRIX3X3: 3;
			case BOOL4, BOOL4V, INT4, INT4V, FLOAT4, FLOAT4V, MATRIX4X4, MATRIX2X2V: 4;

			case MATRIX2X3, MATRIX4X3: 3;
			case MATRIX2X4, MATRIX3X4: 4;
			case MATRIX3X2, MATRIX4X2: 2;

			case MATRIX3X3V: 9;
			case MATRIX4X4V: 16;
			case MATRIX2X3V, MATRIX3X2V: 6;
			case MATRIX2X4V, MATRIX4X2V: 8;
			case MATRIX3X4V, MATRIX4X3V: 12;
			default: 1;
		}
		length *= arrayLength;

		inline function register(x:Any)
		{
			Reflect.setField(__data, name, x);
			if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, x);
		}

		if (Reflect.hasField(__data, name) && Reflect.field(__data, name) != null)
		{
			var dyn = Reflect.field(__data, name);
			if (isSampler)
			{
				var input:ShaderInput<BitmapData> = cast dyn;
				if (input != null)
				{
					if (input.input == null) input.input = null;
					if (location != -1) input.index = location;
					if (__inputBitmapData != null && !__inputBitmapData.contains(input)) __inputBitmapData.push(input);
					return register(input);
				}
			}
			else
			{
				switch (type)
				{
					case BOOL, BOOL2, BOOL3, BOOL4, BOOLV, BOOL2V, BOOL3V, BOOL4V:
						var parameter:ShaderParameter<Bool> = cast dyn;
						if (parameter != null)
						{
							if (parameter.value == null) parameter.value = cast defaultValue;
							if (location != -1) parameter.index = location;
							parameter.__arrayLength = arrayLength;
							parameter.__isUniform = isUniform;
							parameter.__length = length;
							if (__paramBool != null && !__paramBool.contains(cast parameter)) __paramBool.push(cast parameter);
							return register(parameter);
						}
					case INT, INT2, INT3, INT4, INTV, INT2V, INT3V, INT4V:
						var parameter:ShaderParameter<Int> = cast dyn;
						if (parameter != null)
						{
							if (parameter.value == null) parameter.value = cast defaultValue;
							if (location != -1) parameter.index = location;
							parameter.__arrayLength = arrayLength;
							parameter.__isUniform = isUniform;
							parameter.__length = length;
							if (__paramInt != null && !__paramInt.contains(cast parameter)) __paramInt.push(cast parameter);
							return register(parameter);
						}
					default:
						var parameter:ShaderParameter<Float> = cast dyn;
						if (parameter != null)
						{
							if (parameter.value == null) parameter.value = cast defaultValue;
							if (location != -1) parameter.index = location;
							parameter.__arrayLength = arrayLength;
							parameter.__isUniform = isUniform;
							parameter.__length = length;
							if (__paramFloat != null && !__paramFloat.contains(cast parameter)) __paramFloat.push(cast parameter);
							return register(parameter);
						}
				}
			}
		}

		if (isSampler)
		{
			var input = new ShaderInput<BitmapData>();
			input.name = name;
			input.index = location;
			input.__isUniform = true;
			switch (name) {
				case "openfl_Texture": __texture = input;
				case "bitmap": __bitmap = input;
				default:
			}
			if (__inputBitmapData != null) __inputBitmapData.push(input);
			register(input);
		}
		else
		{
			switch (type)
			{
				case BOOL, BOOL2, BOOL3, BOOL4, BOOLV, BOOL2V, BOOL3V, BOOL4V:
					var parameter = new ShaderParameter<Bool>();
					parameter.name = name;
					parameter.index = location;
					parameter.type = type;
					parameter.value = cast defaultValue;
					parameter.__arrayLength = arrayLength;
					parameter.__isBool = true;
					parameter.__isUniform = isUniform;
					parameter.__length = length;
					if (name == "openfl_HasColorTransform")
					{
						__hasColorTransform = parameter;
					}
					if (__paramBool != null) __paramBool.push(parameter);
					register(parameter);

				case INT, INT2, INT3, INT4, INTV, INT2V, INT3V, INT4V:
					var parameter = new ShaderParameter<Int>();
					parameter.name = name;
					parameter.index = location;
					parameter.type = type;
					parameter.value = cast defaultValue;
					parameter.__arrayLength = arrayLength;
					parameter.__isInt = true;
					parameter.__isUniform = isUniform;
					parameter.__length = length;
					if (__paramInt != null) __paramInt.push(parameter);
					register(parameter);

				default:
					var parameter = new ShaderParameter<Float>();
					parameter.name = name;
					parameter.index = location;
					parameter.type = type;
					parameter.value = cast defaultValue;
					parameter.__arrayLength = arrayLength;
					#if lime
					if (arrayLength > 0) parameter.__uniformMatrix = new Float32Array(length);
					#end
					parameter.__isFloat = true;
					parameter.__isUniform = isUniform;
					parameter.__length = length;
					if (__paramFloat != null) __paramFloat.push(parameter);
						
					switch (name)
					{
						case "openfl_Alpha": __alpha = parameter;
						case "openfl_ColorMultiplier": __colorMultiplier = parameter;
						case "openfl_ColorOffset": __colorOffset = parameter;
						case "openfl_Matrix": __matrix = parameter;
						case "openfl_Position": __position = parameter;
						case "openfl_TextureCoord": __textureCoord = parameter;
						case "openfl_TextureSize": __textureSize = parameter;
						default:
					}

					register(parameter);
			}
		}
	}

	@:noCompletion private function __update():Void
	{
		if (program != null)
		{
			__updateGL();
		}
	}

	@:noCompletion private function __updateFromBuffer(shaderBuffer:ShaderBuffer, bufferOffset:Int):Void
	{
		if (program != null)
		{
			__updateGLFromBuffer(shaderBuffer, bufferOffset);
		}
	}

	@:noCompletion private function __updateGL():Void
	{
		var textureCount = 0;

		for (input in __inputBitmapData)
		{
			input.__updateGL(__context, textureCount);
			textureCount++;
		}

		for (parameter in __paramBool)
		{
			parameter.__updateGL(__context);
		}

		for (parameter in __paramFloat)
		{
			parameter.__updateGL(__context);
		}

		for (parameter in __paramInt)
		{
			parameter.__updateGL(__context);
		}
	}

	@:noCompletion private function __updateGLFromBuffer(shaderBuffer:ShaderBuffer, bufferOffset:Int):Void {
		var textureCount = 0;
		var input:ShaderInput<BitmapData>;
		var inputData:BitmapData;
		var inputFilter:Context3DTextureFilter;
		var inputMipFilter:Context3DMipFilter;
		var inputWrap:Context3DWrapMode;

		for (i in 0...shaderBuffer.inputCount) {
			input = shaderBuffer.inputRefs[i];
			inputData = shaderBuffer.inputs[i];
			inputFilter = shaderBuffer.inputFilter[i];
			inputMipFilter = shaderBuffer.inputMipFilter[i];
			inputWrap = shaderBuffer.inputWrap[i];

			if (inputData != null) {
				input.__updateGL(__context, textureCount, inputData, inputFilter, inputMipFilter, inputWrap);
				textureCount++;
			}
		}

		var gl = __context.gl;

		if (shaderBuffer.paramDataLength > 0) {
			if (shaderBuffer.paramDataBuffer == null) {
				shaderBuffer.paramDataBuffer = gl.createBuffer();
			}

			// Log.verbose ("bind param data buffer (length: " + shaderBuffer.paramData.length + ") (" + shaderBuffer.paramCount + ")");

			__context.__bindGLArrayBuffer(shaderBuffer.paramDataBuffer);
			gl.bufferData(gl.ARRAY_BUFFER, shaderBuffer.paramData, gl.DYNAMIC_DRAW);
		} else {
			// Log.verbose ("bind buffer null");

			__context.__bindGLArrayBuffer(null);
		}

		var boolIndex = 0;
		var floatIndex = 0;
		var intIndex = 0;

		var boolCount = shaderBuffer.paramBoolCount;
		var floatCount = shaderBuffer.paramFloatCount;
		var paramData = shaderBuffer.paramData;

		var boolRef:ShaderParameter<Bool>;
		var floatRef:ShaderParameter<Float>;
		var intRef:ShaderParameter<Int>;
		var hasOverride:Bool;
		var overrideBoolValue:Array<Bool> = null;
		var overrideFloatValue:Array<Float> = null;
		var overrideIntValue:Array<Int> = null;

		for (i in 0...shaderBuffer.paramCount) {
			hasOverride = false;

			if (i < boolCount) {
				boolRef = shaderBuffer.paramRefs_Bool[boolIndex];

				for (j in 0...shaderBuffer.overrideBoolCount) {
					if (boolRef.name == shaderBuffer.overrideBoolNames[j]) {
						overrideBoolValue = shaderBuffer.overrideBoolValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					boolRef.__updateGL(__context, overrideBoolValue);
				}
				else
				{
					boolRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				boolIndex++;
			} else if (i < boolCount + floatCount) {
				floatRef = shaderBuffer.paramRefs_Float[floatIndex];

				for (j in 0...shaderBuffer.overrideFloatCount) {
					if (floatRef.name == shaderBuffer.overrideFloatNames[j]) {
						overrideFloatValue = shaderBuffer.overrideFloatValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					floatRef.__updateGL(__context, overrideFloatValue);
				}
				else
				{
					floatRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				floatIndex++;
			} else {
				intRef = shaderBuffer.paramRefs_Int[intIndex];

				for (j in 0...shaderBuffer.overrideIntCount) {
					if (intRef.name == shaderBuffer.overrideIntNames[j]) {
						overrideIntValue = cast shaderBuffer.overrideIntValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					intRef.__updateGL(__context, overrideIntValue);
				}
				else
				{
					intRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				intIndex++;
			}
		}
	}

	// Get & Set Methods
	@:noCompletion private function get_data():ShaderData
	{
		if (__glSourceDirty || __data == null)
		{
			__init();
		}

		return __data;
	}

	@:noCompletion private function set_data(value:ShaderData):ShaderData
	{
		return __data = cast value;
	}

	@:noCompletion private function get_glVersionRaw():Null<String>
	{
		return __glVersionRaw;
	}

	@:noCompletion private function get_glVersion():String
	{
		return __glVersion;
	}

	@:noCompletion private function set_glVersion(value:Null<String>):String
	{
		__glVersionRaw = value;
		if (value == null || value == "") value = getDefaultGLVersion();
		if (value != __glVersion)
		{
			__glSourceDirty = true;
			if (__glVertexSourceRaw != null) __glVertexSource = processGLSLText(__glVertexSourceRaw, value, false, __glVertexPragmas);
			if (__glFragmentSourceRaw != null) __glFragmentSource = processGLSLText(__glFragmentSourceRaw, value, true, __glFragmentPragmas);
		}

		return __glVersion = value;
	}

	@:noCompletion private function get_glVertexExtensions():Array<ShaderExtension>
	{
		return __glVertexExtensions;
	}

	@:noCompletion private function get_glFragmentExtensions():Array<ShaderExtension>
	{
		return __glFragmentExtensions;
	}

	@:noCompletion private function set_glVertexExtensions(value:Array<ShaderExtension>):Array<ShaderExtension>
	{
		if (value != __glVertexExtensions)
		{
			__glSourceDirty = true;
		}

		return __glVertexExtensions = value;
	}

	@:noCompletion private function set_glFragmentExtensions(value:Array<ShaderExtension>):Array<ShaderExtension>
	{
		if (value != __glFragmentExtensions)
		{
			__glSourceDirty = true;
		}

		return __glFragmentExtensions = value;
	}

	@:noCompletion private function get_glVertexPragmas():Map<String, String>
	{
		return __glVertexPragmas;
	}

	@:noCompletion private function get_glFragmentPragmas():Map<String, String>
	{
		return __glFragmentPragmas;
	}

	@:noCompletion private function set_glVertexPragmas(value:Map<String, String>):Map<String, String>
	{
		if (value != __glVertexPragmas)
		{
			__glSourceDirty = true;
		}

		return __glVertexPragmas = value;
	}

	@:noCompletion private function set_glFragmentPragmas(value:Map<String, String>):Map<String, String>
	{
		if (value != __glFragmentPragmas)
		{
			__glSourceDirty = true;
		}

		return __glFragmentPragmas = value;
	}

	@:noCompletion private function get_glFragmentHeaderRaw():String
	{
		return __glFragmentPragmas.get("header");
	}

	@:noCompletion private function get_glFragmentBodyRaw():String
	{
		return __glFragmentPragmas.get("body");
	}

	@:noCompletion private function get_glFragmentSourceRaw():String
	{
		return __glFragmentSourceRaw;
	}

	@:noCompletion private function get_glFragmentSource():String
	{
		return __glFragmentSource;
	}

	@:noCompletion private function set_glFragmentSource(value:String):String
	{
		__glFragmentSourceRaw = value;
		if (value != null)
		{
			if (__glVersion != (__glVersion = getGLSLTextVersion(value, __glVersionRaw)))
			{
				__glSourceDirty = true;
			}
			value = processGLSLText(value, __glVersion, true, __glFragmentPragmas);
		}
		if (value != __glFragmentSource)
		{
			__glSourceDirty = true;
		}

		return __glFragmentSource = value;
	}

	@:noCompletion private function get_glVertexHeaderRaw():String
	{
		return __glVertexPragmas.get("header");
	}

	@:noCompletion private function get_glVertexBodyRaw():String
	{
		return __glVertexPragmas.get("body");
	}

	@:noCompletion private function get_glVertexSourceRaw():String
	{
		return __glVertexSourceRaw;
	}

	@:noCompletion private function get_glVertexSource():String
	{
		return __glVertexSource;
	}

	@:noCompletion private function set_glVertexSource(value:String):String
	{
		__glVertexSourceRaw = value;
		if (value != null)
		{
			if (__glVersion != (__glVersion = getGLSLTextVersion(value, __glVersionRaw)))
			{
				__glSourceDirty = true;
			}
			value = processGLSLText(value, __glVersion, false, __glVertexPragmas);
		}
		if (value != __glVertexSource)
		{
			__glSourceDirty = true;
		}

		return __glVertexSource = value;
	}

	private var __fieldList:Array<String> = null;

	private function thisHasField(name:String)
	{
		// Reflect.hasField(this, name) is REALLY expensive so we cache the result.
		if (__fieldList == null)
		{
			__fieldList = Reflect.fields(this).concat(Type.getInstanceFields(Type.getClass(this)));
		}
		return __fieldList.indexOf(name) != -1;
	}
}
#else
typedef Shader = flash.display.Shader;
#end
