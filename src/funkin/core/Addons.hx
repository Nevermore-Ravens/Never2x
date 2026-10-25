package funkin.core;

import hxjson5.Json5;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

// a mix between psych's mod folder
// and stepmania's song pack system
//
// primarily used as a song pack system
// but can work for scripts/softcoded mods as well
// however it's not its main purpose
@:structInit
@:publicFields
class Addon {
	var directory:String = '';
	var data:AddonData = {
		name: 'Song Pack',
		description: '',
		authors: []
	};
	var enabled:Bool = true;

	public var name(get, never):String;
	function get_name():String return data.name;

	public var description(get, never):String;
	function get_description():String return data.description;

	public var authors(get, never):Array<String>;
	function get_authors():Array<String> return data.authors;

	public function toString():String {
		return 'Name: $name | Description: $description';
	}
}

typedef AddonData = {
	var name:String;
	var description:String;
	var authors:Array<String>;
}

class Addons {
	public static var list:Array<Addon> = [];
	public static var initialized:Bool = false;

	// controls whether the addon system can affect the game
	public static var active:Bool = true;

	public static var current:Addon = null;

	public static function init() {
		if (initialized) return;
		initialized = true;

		Sys.println('Loading addons...');

		Assets.main.getPath = _getPath;
		reload();

		if (list.length > 0) Sys.println('Addons loaded.');
		else Sys.println('No addons exist.');
	}

	// tells you if there are any addons currently enabled/running
	public static function running():Bool {
		if (!active) return false;

		for (addon in list) if (addon.enabled) return true;
		return false;
	}

	public static function reload() {
		list.resize(0);

		var loaded = [];
		inline function loadAddon(key) {
			if (!FileSystem.exists('addons/$key') || !FileSystem.isDirectory('addons/$key') || loaded.contains(key))
				return null;

			var addon:Addon = getFromDisk(key);
			loaded.push(key);
			list.push(addon);

			Sys.println('Addon "${addon.name}" loaded!');
			return addon;
		}

		for (directory in Settings.data.addonsOrder)
			loadAddon(directory);
		for (directory in FileSystem.readDirectory('addons'))
			loadAddon(directory);
	}

	public static function getFromDisk(directory:String):Addon {
		var result:Addon = {
			directory: directory
		};

		var folder:String = 'addons/$directory';
		if (!FileSystem.exists(folder)) return null;

		if (FileSystem.exists('$folder/meta.json')) {
			var file:Dynamic = Json5.parse(File.getContent('$folder/meta.json'));

			for (property in Reflect.fields(file)) {
				if (!Reflect.hasField(result.data, property)) continue;
				Reflect.setField(result.data, property, Reflect.field(file, property));
			}
		} else {
			result.data.name = directory;
		}

		result.enabled = !Settings.data.addonsOff.contains(directory);
		return result;
	}

	public static function get(name:String):Addon {
		for (addon in list) {
			if (addon.name == name) return addon;
		}

		return null;
	}

	static function _getPath(key:String, ?extensions:Array<String>):String {
		// just original Assets.getPath();
		if (list.length == 0 || !running()) {
			var path = new Path('assets/$key');

			// assume there's already a file extension applied
			if (path.ext.length != 0) return path.toString();

			extensions ??= [];
			// this might be faster than exists() ????????
			var files:Array<String> = FileSystem.readDirectory(path.dir);
			for (ext in extensions) {
				if (!files.contains(path.file + '.' + ext)) continue;

				path.ext = ext;
				break;
			}

			return path.toString();
		}

		// basically ^ but treats `addons/${addon.directory}` like
		// its own asset folder
		// that's able to override other asset folders
		//
		// ohhhhhhhhhhh im definitely getting killed for this one
		var mainAddon:Addon = current ?? list[0];
		var hasExtension:Bool = false;
		var path = new Path('');

		path.file = Path.withoutDirectory(key);
		path.ext = Path.extension(key);

		extensions ??= [];

		if (path.ext.length != 0) {
			hasExtension = true;

			var extIndex:Int = path.file.lastIndexOf('.');
			path.file = path.file.substr(0, extIndex);
		} else path.ext = null;

		function updateDirectory(?addon:Addon) {
			var root:String = 'assets';
			if (addon != null) root = 'addons/' + addon.directory; 

			path.dir = root + '/' + Path.directory(key);
		}

		function search() {
			if (hasExtension) {
				return FileSystem.exists(path.toString());
			}

			if (!FileSystem.exists(path.dir)) return false;

			if (extensions.length == 1) {
				path.ext = extensions[0];
				return FileSystem.exists(path.toString());
			}

			for (ext in extensions) {
				path.ext = ext;
				if (FileSystem.exists(path.toString())) return true;
			}

			return false;
		}

		// start by checking the main addon first
		updateDirectory(mainAddon);
		if (search()) return path.toString();

		// if it didn't exist there
		// we now iterate through all addons that are enabled
		for (addon in list) {
			if (!addon.enabled) continue;

			// we already checked the main addon, 
			// we don't need to check it again
			if (addon.directory == mainAddon.directory) continue;

			updateDirectory(addon);
			if (search()) return path.toString();
		}

		// if neither of that worked
		// just search the asset folder like usual
		updateDirectory();
		search();
		return path.toString();
	}
}