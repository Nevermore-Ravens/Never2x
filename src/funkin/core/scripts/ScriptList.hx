package funkin.core.scripts;

import sys.FileSystem;
import haxe.io.Path;

class ScriptList {
	var list:Array<Script> = [];

	public function new() {}

	public function loadFolder(folder:String, ?absolutePath:Bool = false) {
		if (folder.charCodeAt(folder.length - 1) != '/'.code)
			folder += "/";

		var directories:Array<String> = [];
		if (!absolutePath) {
			directories.push('assets/' + folder);
			for (addon in Addons.list) {
				if (!addon.enabled) continue;
				directories.push('addons/${addon.directory}/$folder');
			}
		} else
			directories.push(folder);

		for (dir in directories) {
			if (!FileSystem.exists(dir)) continue;

			for (file in FileSystem.readDirectory(dir)) {
				if (Script.extensions.contains(Path.extension(file)))
					loadFile(dir + file, true);
			}
		}
	}

	public function loadFile(file:String, ?absolutePath:Bool = false):Script {
		file = absolutePath ? file : Assets.main.getPath(file, Script.extensions);
		if (!FileSystem.exists(file))
			return null;

		var script = new Script(file, "", true);
		if (script.interp != null) {
			list.push(script);
			return script;
		}
		return null;
	}

	public function get(val:String):Dynamic {
		var result:Dynamic = null;

		for (script in list) {
			var callResult = script.get(val);
			if (callResult != null)
				result = callResult;
		}

		return result;
	}

	public function set(val:String, ?with:Dynamic):Dynamic {
		for (script in list)
			script.set(val, with);
		return with;
	}

	public function call(name:String, ?args:Array<Dynamic>):Dynamic {
		args ??= [];
		var result:Dynamic = null;

		for (script in list) {
			var callResult = script.call(name, args);
			if (callResult != null)
				result = callResult;
		}

		return result;
	}
}