package funkin.core.scripts;

import nevermore.modchart.ModchartManager;
import nevermore.core.Assets;
import funkin.states.PlayState;

import hscript.Interp;
import hscript.Parser;

class Script {
	public static var extensions:Array<String> = ["hx", "hxs", "hscript"];

	public static var parser:Parser = {
		var result = new Parser();
		result.allowJSON = true;
		result.allowMetadata = true;
		result.allowTypes = true;
		result;
	}
	public var interp:Interp = null;
	public var path:Null<String> = null;
	var curFunc:Null<String> = null;

	public function new(path:Null<String>, ?code:String, ?absolutePath:Bool = false) {
		this.path = absolutePath ? path : Assets.getPath(path);
		code = (path != null && sys.FileSystem.exists(path)) ? sys.io.File.getContent(path) : (code ?? "");

		parser.line = 1;
		var expr:hscript.Expr = null;
		try {
			expr = parser.parseString(code, path ?? "ANON-SCRIPT");
			interp = new Interp();
			interp.onError = onError;
			ScriptDefaults.apply(this);
			interp.execute(expr);
		} catch (err:hscript.Expr.Error) {
			var str = "Failed to parse " + (path ?? "ANON-SCRIPT") + "\n  - " + StringTools.replace(err.toString(), "\n", "\n    - ");
			Sys.println(str);
			interp = null;
		}
	}

	public function get(val:String) {
		return interp == null ? null : interp.variables.get(val);
	}
	public function set(val:String, with:Dynamic) {
		if (interp == null)
			return null;
		interp.variables.set(val, with);
		return with;
	}
	public function call(name:String, ?args:Array<Dynamic>) {
		final func = get(name);
		if (!Reflect.isFunction(func))
			return null;

		var lastFunc = curFunc;
		curFunc = name;
		var result:Dynamic = Reflect.callMethod(null, func, args ?? []);
		curFunc = lastFunc;

		return result;
	}

	function onError(err:hscript.Expr.Error) {
		var suffix = " on " + (path ?? "ANON-SCRIPT") + "\n  - " + StringTools.replace(err.toString(), "\n", "\n    - ");
		if (curFunc != null)
			Sys.println('Failed to run "$curFunc"' + suffix);
		else
			Sys.println('Failed to run code' + suffix);
	}
}