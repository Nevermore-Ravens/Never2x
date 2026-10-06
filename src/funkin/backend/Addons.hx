package funkin.backend;

import hxjson5.Json5;
import sys.FileSystem;
import sys.io.File;

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

	public static function reload() {
		list.resize(0);

		for (directory in FileSystem.readDirectory('addons')) {
			if (!FileSystem.isDirectory('addons/$directory')) continue;
			var addon:Addon = getFromDisk(directory);
			list.push(addon);

			Sys.println('Addon "${addon.name}" loaded!');
		}
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

		return result;
	}

	public static function get(name:String):Addon {
		for (addon in list) {
			if (addon.name == name) return addon;
		}

		return null;
	}

	static function _getPath(key:String):String {
		if (list.length > 0) {
			var currentAddon = (current ?? list[0]);
			var directory:String = currentAddon.directory;
			var path:String = '';

			function getRedirect():String return 'addons/' + directory + '/' + key;
			
			path = getRedirect();
			if (FileSystem.exists(path)) return path;

			for (addon in list) {
				if (!addon.enabled) continue;
				if (addon.directory == currentAddon.directory) continue;

				directory = addon.directory;
				path = getRedirect();

				// `FileSystem.exists()` can be really expensive
				// if used too often, so make sure you don't have
				// too many addons enabled at once
				if (FileSystem.exists(path)) return path;
			}
		}

		return 'assets/$key';
	}
}