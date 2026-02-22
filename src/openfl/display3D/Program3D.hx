package openfl.display3D;

#if !flash
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.display3D._internal.GLUniformLocation;
import openfl.display3D._internal.AGALConverter;
import openfl.display._internal.SamplerState;
import openfl.utils._internal.Float32Array;
import openfl.utils._internal.Log;
import openfl.display.Shader;
import openfl.display.ShaderParameterType;
import openfl.errors.IllegalOperationError;
import openfl.utils.ByteArray;
import openfl.Vector;
#if lime
import lime.graphics.opengl.GL;
import lime.utils.BytePointer;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
@:access(openfl.display.Shader)
@:access(openfl.display.Stage)
@:final class Program3D
{
	private static function getParameterTypeFromGL(type:Int, size:Int):Null<ShaderParameterType>
	{
		return switch (type)
		{
			case lime.graphics.opengl.GL.BOOL: size > 1 ? BOOLV : BOOL;
			case lime.graphics.opengl.GL.FLOAT: size > 1 ? FLOATV : FLOAT;
			case lime.graphics.opengl.GL.INT, lime.graphics.opengl.GL.UNSIGNED_INT: size > 1 ? INTV : INT;
			case lime.graphics.opengl.GL.BOOL_VEC2: size > 1 ? BOOL2V : BOOL2;
			case lime.graphics.opengl.GL.BOOL_VEC3: size > 1 ? BOOL3V : BOOL3;
			case lime.graphics.opengl.GL.BOOL_VEC4: size > 1 ? BOOL4V : BOOL4;
			case lime.graphics.opengl.GL.INT_VEC2, lime.graphics.opengl.GL.UNSIGNED_INT_VEC2: size > 1 ? INT2V : INT2;
			case lime.graphics.opengl.GL.INT_VEC3, lime.graphics.opengl.GL.UNSIGNED_INT_VEC3: size > 1 ? INT3V : INT3;
			case lime.graphics.opengl.GL.INT_VEC4, lime.graphics.opengl.GL.UNSIGNED_INT_VEC4: size > 1 ? INT4V : INT4;
			case lime.graphics.opengl.GL.FLOAT_VEC2: size > 1 ? FLOAT2V : FLOAT2;
			case lime.graphics.opengl.GL.FLOAT_VEC3: size > 1 ? FLOAT3V : FLOAT3;
			case lime.graphics.opengl.GL.FLOAT_VEC4: size > 1 ? FLOAT4V : FLOAT4;
			case lime.graphics.opengl.GL.FLOAT_MAT2: size > 1 ? MATRIX2X2V : MATRIX2X2;
			case lime.graphics.opengl.GL.FLOAT_MAT2x3: size > 1 ? MATRIX2X3V : MATRIX2X3;
			case lime.graphics.opengl.GL.FLOAT_MAT2x4: size > 1 ? MATRIX2X4V : MATRIX2X4;
			case lime.graphics.opengl.GL.FLOAT_MAT3x2: size > 1 ? MATRIX3X2V : MATRIX3X2;
			case lime.graphics.opengl.GL.FLOAT_MAT3: size > 1 ? MATRIX3X3V : MATRIX3X3;
			case lime.graphics.opengl.GL.FLOAT_MAT3x4: size > 1 ? MATRIX3X4V : MATRIX3X4;
			case lime.graphics.opengl.GL.FLOAT_MAT4x2: size > 1 ? MATRIX4X2V : MATRIX4X2;
			case lime.graphics.opengl.GL.FLOAT_MAT4x3: size > 1 ? MATRIX4X3V : MATRIX4X3;
			case lime.graphics.opengl.GL.FLOAT_MAT4: size > 1 ? MATRIX4X4V : MATRIX4X4;
			default: null;
		}
	}

	private static function getParameterTypeFromGLString(string:String, size:Int):Null<ShaderParameterType>
	{
		return switch (string)
		{
			case "bool": size > 1 ? BOOLV : BOOL;
			case "double", "float": size > 1 ? FLOATV : FLOAT;
			case "int", "uint": size > 1 ? INTV : INT;
			case "bvec2": size > 1 ? BOOL2V : BOOL2;
			case "bvec3": size > 1 ? BOOL3V : BOOL3;
			case "bvec4": size > 1 ? BOOL4V : BOOL4;
			case "ivec2", "uvec2": size > 1 ? INT2V : INT2;
			case "ivec3", "uvec3": size > 1 ? INT3V : INT3;
			case "ivec4", "uvec4": size > 1 ? INT4V : INT4;
			case "vec2", "dvec2": size > 1 ? FLOAT2V : FLOAT2;
			case "vec3", "dvec3": size > 1 ? FLOAT3V : FLOAT3;
			case "vec4", "dvec4": size > 1 ? FLOAT4V : FLOAT4;
			case "mat2", "mat2x2": size > 1 ? MATRIX2X2V : MATRIX2X2;
			case "mat2x3": size > 1 ? MATRIX2X3V : MATRIX2X3;
			case "mat2x4": size > 1 ? MATRIX2X4V : MATRIX2X4;
			case "mat3x2": size > 1 ? MATRIX3X2V : MATRIX3X2;
			case "mat3", "mat3x3": size > 1 ? MATRIX3X3V : MATRIX3X3;
			case "mat3x4": size > 1 ? MATRIX3X4V : MATRIX3X4;
			case "mat4x2": size > 1 ? MATRIX4X2V : MATRIX4X2;
			case "mat4x3": size > 1 ? MATRIX4X3V : MATRIX4X3;
			case "mat4", "mat4x4": size > 1 ? MATRIX4X4V : MATRIX4X4;
			default: null;
		}
	}

	@:noCompletion private var __context:Context3D;
	@:noCompletion private var __format:Context3DProgramFormat;
	@:noCompletion private var __agalAlphaSamplerEnabled:Array<Uniform>;
	@:noCompletion private var __agalAlphaSamplerUniforms:List<Uniform>;
	@:noCompletion private var __agalFragmentUniformMap:UniformMap;
	@:noCompletion private var __agalPositionScale:Uniform;
	@:noCompletion private var __agalSamplerUniforms:List<Uniform>;
	@:noCompletion private var __agalSamplerUsageMask:Int;
	@:noCompletion private var __agalUniforms:List<Uniform>;
	@:noCompletion private var __agalVertexUniformMap:UniformMap;
	@:noCompletion private var __glFragmentShader:GLShader;
	@:noCompletion private var __glVertexShader:GLShader;
	@:noCompletion private var __glFragmentSource:String;
	@:noCompletion private var __glVertexSource:String;
	@:noCompletion private var __glProgram:GLProgram;
	@:noCompletion private var __glslSamplerLocations:Array<Int>;
	@:noCompletion private var __glslSamplerDefaults:Array<String>;
	@:noCompletion private var __glslSamplerNames:Array<String>;
	@:noCompletion private var __glslAttribLocations:Array<Int>;
	@:noCompletion private var __glslAttribNames:Array<String>;
	@:noCompletion private var __glslAttribTypes:Array<ShaderParameterType>;
	@:noCompletion private var __glslAttribSizes:Array<Int>;
	@:noCompletion private var __glslUniformLocations:Array<Int>;
	@:noCompletion private var __glslUniformDefaults:Array<Dynamic>;
	@:noCompletion private var __glslUniformNames:Array<String>;
	@:noCompletion private var __glslUniformTypes:Array<ShaderParameterType>;
	@:noCompletion private var __glslUniformSizes:Array<Int>;
	@:noCompletion private var __samplerStates:Array<SamplerState>;

	@:noCompletion private function new(context3D:Context3D, format:Context3DProgramFormat)
	{
		__context = context3D;
		__format = format;

		if (__format == AGAL)
		{
			__agalSamplerUsageMask = 0;
			__agalUniforms = new List<Uniform>();
			__agalSamplerUniforms = new List<Uniform>();
			__agalAlphaSamplerUniforms = new List<Uniform>();
			__agalAlphaSamplerEnabled = new Array<Uniform>();
		}
		else
		{
			__glslSamplerLocations = new Array();
			__glslSamplerDefaults = new Array();
			__glslSamplerNames = new Array();
			__glslAttribLocations = new Array();
			__glslAttribNames = new Array();
			__glslAttribTypes = new Array();
			__glslAttribSizes = new Array();
			__glslUniformLocations = new Array();
			__glslUniformDefaults = new Array();
			__glslUniformNames = new Array();
			__glslUniformTypes = new Array();
			__glslUniformSizes = new Array();
		}

		__samplerStates = new Array<SamplerState>();
	}

	public function dispose():Void
	{
		__deleteShaders();
	}

	public function getAttributeIndex(name:String):Int
	{
		if (__format == AGAL)
		{
			// TODO: Validate that it exists in the current program

			if (StringTools.startsWith(name, "va"))
			{
				return Std.parseInt(name.substring(2));
			}
			else
			{
				return -1;
			}
		}
		else
		{
			for (i in 0...__glslAttribNames.length)
			{
				if (__glslAttribNames[i] == name) return __glslAttribLocations[i];
			}

			return -1;
		}
	}

	public function getConstantIndex(name:String):Int
	{
		if (__format == AGAL)
		{
			// TODO: Validate that it exists in the current program

			if (StringTools.startsWith(name, "vc"))
			{
				return Std.parseInt(name.substring(2));
			}
			else if (StringTools.startsWith(name, "fc"))
			{
				return Std.parseInt(name.substring(2));
			}
			else
			{
				return -1;
			}
		}
		else
		{
			for (i in 0...__glslUniformNames.length)
			{
				if (__glslUniformNames[i] == name) return __glslUniformLocations[i];
			}

			return -1;
		}
	}

	public function upload(vertexProgram:ByteArray, fragmentProgram:ByteArray):Void
	{
		if (__format != AGAL) throw "Program3D.upload is AGAL only, use uploadSources";

		// var samplerStates = new Vector<SamplerState> (Context3D.MAX_SAMPLERS);
		var samplerStates = new Array<SamplerState>();

		var glslVertex = AGALConverter.convertToGLSL(vertexProgram, null);
		var glslFragment = AGALConverter.convertToGLSL(fragmentProgram, samplerStates);

		if (Log.level == LogLevel.VERBOSE)
		{
			Log.info(glslVertex);
			Log.info(glslFragment);
		}

		__deleteShaders();
		__uploadFromGLSL(glslVertex, glslFragment);
		__buildAGALUniformList();

		for (i in 0...samplerStates.length)
		{
			__samplerStates[i] = samplerStates[i];
		}
	}

	public function uploadSources(vertexSource:String, fragmentSource:String):Void
	{
		if (__format != GLSL) throw "Program3D.uploadSources is GL only, use upload";

		if (vertexSource == __glVertexSource && fragmentSource == __glFragmentSource) return;

		__deleteShaders();

		#if haxe4
		__glslSamplerLocations.resize(0);
		__glslSamplerDefaults.resize(0);
		__glslSamplerNames.resize(0);
		__glslAttribLocations.resize(0);
		__glslAttribNames.resize(0);
		__glslAttribTypes.resize(0);
		__glslAttribSizes.resize(0);
		__glslUniformLocations.resize(0);
		__glslUniformDefaults.resize(0);
		__glslUniformNames.resize(0);
		__glslUniformTypes.resize(0);
		__glslUniformSizes.resize(0);
		#else
		__glslSamplerLocations = new Array();
		__glslSamplerDefaults = new Array();
		__glslSamplerNames = new Array();
		__glslAttribLocations = new Array();
		__glslAttribNames = new Array();
		__glslAttribTypes = new Array();
		__glslAttribSizes = new Array();
		__glslUniformLocations = new Array();
		__glslUniformDefaults = new Array();
		__glslUniformNames = new Array();
		__glslUniformTypes = new Array();
		__glslUniformSizes = new Array();
		#end

		vertexSource = Shader.processGLSLData(vertexSource, "attribute", __processGLSLData);
		vertexSource = Shader.processGLSLData(vertexSource, "in", __processGLSLData);
		vertexSource = Shader.processGLSLData(vertexSource, "uniform", __processGLSLData);
		fragmentSource = Shader.processGLSLData(fragmentSource, "uniform", __processGLSLData);

		__uploadFromGLSL(vertexSource, fragmentSource);
		__buildGLSLParamList();
	}

	@:noCompletion private function __deleteShaders():Void
	{
		var gl = __context.gl;

		if (__glProgram != null)
		{
			gl.deleteProgram(__glProgram);
			__glProgram = null;
		}

		if (__glVertexShader != null)
		{
			gl.deleteShader(__glVertexShader);
			__glVertexShader = null;
		}

		if (__glFragmentShader != null)
		{
			gl.deleteShader(__glFragmentShader);
			__glFragmentShader = null;
		}
	}

	@:noCompletion private function __disable():Void
	{
		if (__format == GLSL)
		{
			// var gl = __context.gl;
			// var textureCount = 0;

			// for (input in __glslInputBitmapData) {

			// 	input.__disableGL (__context, textureCount);
			// 	textureCount++;

			// }

			// for (parameter in __glslParamBool) {

			// 	parameter.__disableGL (__context);

			// }

			// for (parameter in __glslParamFloat) {

			// 	parameter.__disableGL (__context);

			// }

			// for (parameter in __glslParamInt) {

			// 	parameter.__disableGL (__context);

			// }

			// // __context.__bindGLArrayBuffer (null);

			// if (__context.__context.type == OPENGL) {

			// 	gl.disable (gl.TEXTURE_2D);

			// }
		}
	}

	@:noCompletion private function __enable():Void
	{
		var gl = __context.gl;
		gl.useProgram(__glProgram);

		if (__format == AGAL)
		{
			__agalVertexUniformMap.markAllDirty();
			__agalFragmentUniformMap.markAllDirty();

			for (sampler in __agalSamplerUniforms)
			{
				if (sampler.regCount == 1)
				{
					gl.uniform1i(sampler.location, sampler.regIndex);
				}
				else
				{
					throw new IllegalOperationError("!!! TODO: uniform location on webgl");
				}
			}

			for (sampler in __agalAlphaSamplerUniforms)
			{
				if (sampler.regCount == 1)
				{
					gl.uniform1i(sampler.location, sampler.regIndex);
				}
				else
				{
					throw new IllegalOperationError("!!! TODO: uniform location on webgl");
				}
			}
		}
		else
		{
			// var textureCount = 0;

			// var gl = __context.gl;

			// for (input in __glslInputBitmapData) {

			// 	gl.uniform1i (input.index, textureCount);
			// 	textureCount++;

			// }

			// if (__context.__context.type == OPENGL && textureCount > 0) {

			// 	gl.enable (gl.TEXTURE_2D);

			// }
		}
	}

	@:noCompletion private function __flush():Void
	{
		if (__format == AGAL)
		{
			__agalVertexUniformMap.flush();
			__agalFragmentUniformMap.flush();
		}
		else
		{
			// TODO
			return;

			// var textureCount = 0;

			// for (input in __glslInputBitmapData) {

			// 	input.__updateGL (__context, textureCount);
			// 	textureCount++;

			// }

			// for (parameter in __glslParamBool) {

			// 	parameter.__updateGL (__context);

			// }

			// for (parameter in __glslParamFloat) {

			// 	parameter.__updateGL (__context);

			// }

			// for (parameter in __glslParamInt) {

			// 	parameter.__updateGL (__context);

			// }
		}
	}

	@:noCompletion private function __getSamplerState(sampler:Int):SamplerState
	{
		return __samplerStates[sampler];
	}

	@:noCompletion private function __markDirty(isVertex:Bool, index:Int, count:Int):Void
	{
		if (__format == GLSL) return;

		if (isVertex)
		{
			__agalVertexUniformMap.markDirty(index, count);
		}
		else
		{
			__agalFragmentUniformMap.markDirty(index, count);
		}
	}

	@:noCompletion private function __buildAGALUniformList():Void
	{
		if (__format == GLSL) return;

		#if lime
		var gl = __context.gl;

		__agalUniforms.clear();
		__agalSamplerUniforms.clear();
		__agalAlphaSamplerUniforms.clear();
		__agalAlphaSamplerEnabled = [];

		__agalSamplerUsageMask = 0;

		var numActive = 0;
		numActive = gl.getProgramParameter(__glProgram, gl.ACTIVE_UNIFORMS);

		var vertexUniforms = new List<Uniform>();
		var fragmentUniforms = new List<Uniform>();

		for (i in 0...numActive)
		{
			var info = gl.getActiveUniform(__glProgram, i);
			var name = info.name;
			var size = info.size;
			var uniformType = info.type;

			var uniform = new Uniform(__context);
			uniform.name = name;
			uniform.size = size;
			uniform.type = uniformType;

			uniform.location = gl.getUniformLocation(__glProgram, uniform.name);

			var indexBracket = uniform.name.indexOf("[");

			if (indexBracket >= 0)
			{
				uniform.name = uniform.name.substring(0, indexBracket);
			}

			switch (uniform.type)
			{
				case GL.FLOAT_MAT2:
					uniform.regCount = 2;
				case GL.FLOAT_MAT3:
					uniform.regCount = 3;
				case GL.FLOAT_MAT4:
					uniform.regCount = 4;
				default:
					uniform.regCount = 1;
			}

			uniform.regCount *= uniform.size;

			__agalUniforms.add(uniform);

			if (uniform.name == "vcPositionScale")
			{
				__agalPositionScale = uniform;
			}
			else if (StringTools.startsWith(uniform.name, "vc"))
			{
				uniform.regIndex = Std.parseInt(uniform.name.substring(2));
				uniform.regData = __context.__vertexConstants;
				vertexUniforms.add(uniform);
			}
			else if (StringTools.startsWith(uniform.name, "fc"))
			{
				uniform.regIndex = Std.parseInt(uniform.name.substring(2));
				uniform.regData = __context.__fragmentConstants;
				fragmentUniforms.add(uniform);
			}
			else if (StringTools.startsWith(uniform.name, "sampler") && uniform.name.indexOf("alpha") == -1)
			{
				uniform.regIndex = Std.parseInt(uniform.name.substring(7));
				__agalSamplerUniforms.add(uniform);

				for (reg in 0...uniform.regCount)
				{
					__agalSamplerUsageMask |= (1 << (uniform.regIndex + reg));
				}
			}
			else if (StringTools.startsWith(uniform.name, "sampler") && StringTools.endsWith(uniform.name, "_alpha"))
			{
				var len = uniform.name.indexOf("_") - 7;
				uniform.regIndex = Std.parseInt(uniform.name.substring(7, 7 + len)) + 4;
				__agalAlphaSamplerUniforms.add(uniform);
			}
			else if (StringTools.startsWith(uniform.name, "sampler") && StringTools.endsWith(uniform.name, "_alphaEnabled"))
			{
				uniform.regIndex = Std.parseInt(uniform.name.substring(7));
				__agalAlphaSamplerEnabled[uniform.regIndex] = uniform;
			}

			if (Log.level == LogLevel.VERBOSE)
			{
				Log.verbose('${i} name:${uniform.name} type:${uniform.type} size:${uniform.size} location:${uniform.location}');
			}
		}

		__agalVertexUniformMap = new UniformMap(Lambda.array(vertexUniforms));
		__agalFragmentUniformMap = new UniformMap(Lambda.array(fragmentUniforms));
		#end
	}

	@:noCompletion private function __setPositionScale(positionScale:Float32Array):Void
	{
		if (__format == GLSL) return;

		if (__agalPositionScale != null)
		{
			var gl = __context.gl;
			gl.uniform4fv(__agalPositionScale.location, positionScale);
		}
	}

	@:noCompletion private function __setSamplerState(sampler:Int, state:SamplerState):Void
	{
		__samplerStates[sampler] = state;
	}

	@:noCompletion private function __createGLSLShader(source:String, type:Int):GLShader
	{
		var gl = __context.gl;

		var glShader = gl.createShader(type);
		gl.shaderSource(glShader, source);
		gl.compileShader(glShader);

		var shaderInfoLog = gl.getShaderInfoLog(glShader);
		var hasInfoLog = shaderInfoLog != null && StringTools.trim(shaderInfoLog) != "";
		var isError = gl.getShaderParameter(glShader, gl.COMPILE_STATUS) == 0;

		if (hasInfoLog || isError)
		{
			__logGLShaderInfo(isError, type, shaderInfoLog, source);
		}

		return glShader;
	}

	@:noCompletion private function __uploadFromGLSL(vertexShaderSource:String, fragmentShaderSource:String):Void
	{
		var gl = __context.gl;

		__glVertexShader = __createGLSLShader(__glVertexSource = vertexShaderSource, gl.VERTEX_SHADER);
		__glFragmentShader = __createGLSLShader(__glFragmentSource = fragmentShaderSource, gl.FRAGMENT_SHADER);
		__glProgram = gl.createProgram();

		gl.attachShader(__glProgram, __glVertexShader);
		gl.attachShader(__glProgram, __glFragmentShader);
		gl.linkProgram(__glProgram);

		if (gl.getProgramParameter(__glProgram, gl.LINK_STATUS) == 0)
		{
			Log.error("Unable to initialize the shader program\n" + gl.getProgramInfoLog(__glProgram));
		}

		if (__format == AGAL)
		{
			// TODO: AGAL version specific number of attributes?
			for (i in 0...16)
			{
				// for (i in 0...Context3D.MAX_ATTRIBUTES) {

				var name = "va" + i;

				if (vertexShaderSource.indexOf(" " + name) != -1)
				{
					gl.bindAttribLocation(__glProgram, i, name);
				}
			}
		}
		else
		{
			// Fix support for drivers that don't draw if attribute 0 is disabled (just mainly for openfl old filter shaders)
			if (gl.getAttribLocation(__glProgram, "openfl_Position") > 0)
			{
				gl.bindAttribLocation(__glProgram, 0, "openfl_Position");
			}
		}
	}

	@:noCompletion private function __buildGLSLParamList():Void
	{
		var gl = __context.gl;
		var idx:Int, name:String, info;
		var regexName = ~/([A-Za-z0-9_]+)(?:\[(\w+)\])?/;

		var num = gl.getProgramParameter(__glProgram, gl.ACTIVE_ATTRIBUTES);
		for (i in 0...num)
		{
			regexName.match((info = gl.getActiveAttrib(__glProgram, i)).name);
			idx = __glslAttribNames.indexOf(name = regexName.matched(1));
			if (idx == -1)
			{
				__glslAttribLocations.push(gl.getAttribLocation(__glProgram, info.name));
				__glslAttribNames.push(name);
				__glslAttribTypes.push(getParameterTypeFromGL(info.type, info.size));
				__glslAttribSizes.push(info.size);
			}
			else
			{
				__glslAttribLocations[idx] = gl.getAttribLocation(__glProgram, info.name);
				__glslAttribTypes[idx] = getParameterTypeFromGL(info.type, info.size);
				__glslAttribSizes[idx] = info.size;
			}
		}

		var num = gl.getProgramParameter(__glProgram, gl.ACTIVE_UNIFORMS);
		for (i in 0...num)
		{
			regexName.match((info = gl.getActiveUniform(__glProgram, i)).name);
			name = regexName.matched(1);
			if (info.type == gl.SAMPLER_2D || info.type == gl.SAMPLER_CUBE)
			{
				idx = __glslSamplerNames.indexOf(name);
				if (idx == -1)
				{
					__glslSamplerLocations.push(gl.getUniformLocation(__glProgram, info.name));
					__glslSamplerDefaults.push(null);
					__glslSamplerNames.push(name);
				}
				else
				{
					__glslSamplerLocations[idx] = gl.getUniformLocation(__glProgram, info.name);
				}
			}
			else
			{
				idx = __glslUniformNames.indexOf(name);
				if (idx == -1)
				{
					__glslUniformLocations.push(gl.getUniformLocation(__glProgram, info.name));
					__glslUniformDefaults.push(null);
					__glslUniformNames.push(name);
					__glslUniformTypes.push(getParameterTypeFromGL(info.type, info.size));
					__glslUniformSizes.push(info.size);
				}
				else
				{
					__glslUniformLocations[idx] = gl.getUniformLocation(__glProgram, info.name);
					__glslUniformTypes[idx] = getParameterTypeFromGL(info.type, info.size);
					__glslUniformSizes[idx] = info.size;
				}
			}
		}
	}

	@:noCompletion private function __processGLSLData(storageType:String, type:ShaderParameterType,
		typeName:String, name:String, arrLength:Int, arrString:String, defaultValue:Dynamic):String
	{
		if (storageType == "uniform")
		{
			if (StringTools.startsWith(typeName, "sampler"))
			{
				__glslSamplerLocations.push(-1);
				__glslSamplerDefaults.push(cast defaultValue);
				__glslSamplerNames.push(name);
			}
			else
			{
				__glslUniformLocations.push(-1);
				__glslUniformDefaults.push(defaultValue);
				__glslUniformNames.push(name);
				__glslUniformTypes.push(type);
				__glslUniformSizes.push(arrLength);
			}
		}
		else
		{
			__glslAttribLocations.push(-1);
			__glslAttribNames.push(name);
			__glslAttribTypes.push(type);
			__glslAttribSizes.push(arrLength);
		}
		return arrString == null ? '$storageType $typeName $name' : '$storageType $typeName $name[$arrString]';
	}

	/**
	 * Retrieves the line number from a shader log line.
	 */
	#if windows
	// 0(5) : whatever
	@:noCompletion private var __lineExtractor = ~/^\d+\((\d+)\) : (.+$)/;
	#else // (html5 || macos || linux)
	// ERROR: 0:5:whatever
	@:noCompletion private var __lineExtractor = ~/^\w+?: \d+:(\d+):(.+$)/;
	#end

	/**
	 * Searches for strings that have only whitespace.
	 * 
	 * **Note:** Searching for all whitespace via `~/^\s*$/` caused false-negatives,
	 * notably: `String.fromCharCode(0)` is `false` but `\W` is `true`.
	 */
	@:noCompletion private var __isEmptyLine = ~/^\W*$/;

	@:noCompletion private function __logGLShaderInfo(isError:Bool, type:Int, infoLog:String, source:String):Void {
		var message = "";
		var lines = source.split("\n");
		var failingLine:String = null;
		for (log in infoLog.split("\n")) {
			// ignore empty lines
			if (__isEmptyLine.match(log))
				continue;

			// look for a line number
			if (!__lineExtractor.match(log)) {
				// Could not find expected info, abort pretty formatting
				failingLine = log;
				break;
			}

			var lineNumberStr = __lineExtractor.matched(1);
			var lineNumber = Std.parseInt(lineNumberStr);
			var info = __lineExtractor.matched(2);
			if (lineNumber >= lines.length) {
				// EOF errors will not have a valid line
				message += '\n\n $lineNumber | $info';
			} else {
				// Add the relevant line to each log
				var line = lines[lineNumber - 1];
				var indent = StringTools.lpad("|", " ", lineNumberStr.length + 3);
				#if haxe4
				var pos = getSourcePos(lines, lineNumber - 1);
				message += '\n\n${pos.file}:${pos.lineNumber}\n ${pos.lineNumber} | $line\n$indent ${info}';
				#else
				message += '\n\n $lineNumber | $line\n$indent ${info}';
				#end
			}
		}

		// If we couldn't parse the logs, output the old, verbose format
		if (failingLine != null)
			message = '\nFailed to simplify log:"$failingLine"\n$infoLog\n$source';

		var typeName = (type == __context.gl.VERTEX_SHADER) ? "vertex" : "fragment";
		if (isError) {
			Log.error('Error compiling $typeName shader $message');
		} else
			Log.debug('Info compiling $typeName shader $message');
	}

	function getSourcePos(lines:Array<String>, lineNumber:Int):{file:String, lineNumber:Int} {
		var nests = 0;
		var i = lineNumber;
		var linesBack = 0;
		while (i-- > 0) {
			if (lines[i].indexOf("openfl_endregion") != -1)
				nests++;

			if (nests == 0)
				linesBack++;

			if (lines[i].indexOf("openfl_region") != -1) {
				if (nests == 0)
					break;
				nests--;
			}
		}

		var sourceData = lines[i].split("// { openfl_region       ")[1].split(":");
		return {
			file: sourceData[0],
			lineNumber: Std.parseInt(sourceData[1]) + linesBack - 1
		};
	}
}

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@SuppressWarnings("checkstyle:FieldDocComment")
@:dox(hide) @:noCompletion class Uniform
{
	public var name:String;
	public var location:GLUniformLocation;
	public var type:Int;
	public var size:Int;
	public var regData:Float32Array;
	public var regIndex:Int;
	public var regCount:Int;
	public var isDirty:Bool;
	public var context:Context3D;
	#if lime
	public var regDataPointer:BytePointer;
	#end

	public function new(context:Context3D)
	{
		this.context = context;

		isDirty = true;

		#if lime
		regDataPointer = new BytePointer();
		#end
	}

	public function flush():Void
	{
		#if lime
		#if (js && html5)
		var gl = context.gl;
		#else
		var gl = context.__context.gles2;
		#end

		var index:Int = regIndex * 4;
		switch (type)
		{
			#if (js && html5)
			case GL.FLOAT_MAT2:
				gl.uniformMatrix2fv(location, false, __getUniformRegisters(index, size * 2 * 2));
			case GL.FLOAT_MAT3:
				gl.uniformMatrix3fv(location, false, __getUniformRegisters(index, size * 3 * 3));
			case GL.FLOAT_MAT4:
				gl.uniformMatrix4fv(location, false, __getUniformRegisters(index, size * 4 * 4));
			case GL.FLOAT_VEC2:
				gl.uniform2fv(location, __getUniformRegisters(index, regCount * 2));
			case GL.FLOAT_VEC3:
				gl.uniform3fv(location, __getUniformRegisters(index, regCount * 3));
			case GL.FLOAT_VEC4:
				gl.uniform4fv(location, __getUniformRegisters(index, regCount * 4));
			default:
				gl.uniform4fv(location, __getUniformRegisters(index, regCount * 4));
			#else
			case GL.FLOAT_MAT2:
				gl.uniformMatrix2fv(location, size, false, __getUniformRegisters(index, size * 2 * 2));
			case GL.FLOAT_MAT3:
				gl.uniformMatrix3fv(location, size, false, __getUniformRegisters(index, size * 3 * 3));
			case GL.FLOAT_MAT4:
				gl.uniformMatrix4fv(location, size, false, __getUniformRegisters(index, size * 4 * 4));
			case GL.FLOAT_VEC2:
				gl.uniform2fv(location, regCount, __getUniformRegisters(index, regCount * 2));
			case GL.FLOAT_VEC3:
				gl.uniform3fv(location, regCount, __getUniformRegisters(index, regCount * 3));
			case GL.FLOAT_VEC4:
				gl.uniform4fv(location, regCount, __getUniformRegisters(index, regCount * 4));
			default:
				gl.uniform4fv(location, regCount, __getUniformRegisters(index, regCount * 4));
			#end
		}
		#end
	}

	#if (js && html5)
	@:noCompletion private inline function __getUniformRegisters(index:Int, size:Int):Float32Array
	{
		return regData.subarray(index, index + size);
	}
	#elseif lime
	@:noCompletion private inline function __getUniformRegisters(index:Int, size:Int):BytePointer
	{
		regDataPointer.set(regData, index * 4);
		return regDataPointer;
	}
	#else
	@:noCompletion private inline function __getUniformRegisters(index:Int, size:Int):Dynamic
	{
		return regData.subarray(index, index + size);
	}
	#end
}

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@SuppressWarnings("checkstyle:FieldDocComment")
@:dox(hide) @:noCompletion class UniformMap
{
	// TODO: it would be better to use a bitmask with a dirty bit per uniform, but not super important now
	@:noCompletion private var __allDirty:Bool;
	@:noCompletion private var __anyDirty:Bool;
	@:noCompletion private var __registerLookup:Array<Uniform>;
	@:noCompletion private var __uniforms:Array<Uniform>;

	public function new(list:Array<Uniform>)
	{
		__uniforms = list;

		__uniforms.sort(function(a, b):Int
		{
			return Reflect.compare(a.regIndex, b.regIndex);
		});

		var total = 0;

		for (uniform in __uniforms)
		{
			if (uniform.regIndex + uniform.regCount > total)
			{
				total = uniform.regIndex + uniform.regCount;
			}
		}

		__registerLookup = [];
		#if haxe4
		__registerLookup.resize(total);
		#end

		for (uniform in __uniforms)
		{
			for (i in 0...uniform.regCount)
			{
				__registerLookup[uniform.regIndex + i] = uniform;
			}
		}

		__anyDirty = __allDirty = true;
	}

	public function flush():Void
	{
		if (__anyDirty)
		{
			for (uniform in __uniforms)
			{
				if (__allDirty || uniform.isDirty)
				{
					uniform.flush();
					uniform.isDirty = false;
				}
			}

			__anyDirty = __allDirty = false;
		}
	}

	public function markAllDirty():Void
	{
		__allDirty = true;
		__anyDirty = true;
	}

	public function markDirty(start:Int, count:Int):Void
	{
		if (__allDirty)
		{
			return;
		}

		var end = start + count;

		if (end > __registerLookup.length)
		{
			end = __registerLookup.length;
		}

		var index = start;

		while (index < end)
		{
			var uniform = __registerLookup[index];

			if (uniform != null)
			{
				uniform.isDirty = true;
				__anyDirty = true;

				index = uniform.regIndex + uniform.regCount;
			}
			else
			{
				index++;
			}
		}
	}
}
#else
typedef Program3D = flash.display3D.Program3D;
#end
