package funkin.core;

import nevermore.play.Strumline;
import nevermore.skins.Noteskin;
import nevermore.Nevermore;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

@:structInit
@:publicFields
class NoteskinMeta {
    var key:String;
    var name:String;
    var styleKeys:Array<String>;
    var styleNames:Map<String, String>;
	var colors:Array<Array<Int>>;
}

class NoteStyling {
	public function getStyle(style:String, ?force:Bool = false) {
		return (Settings.data.noteSkinStyle == "default" || force) ? style : Settings.data.noteSkinStyle;
	}

	public static function getSkinAndStyle(key:String, style:String, ?force:Bool) {
		return Noteskin.get('skins/' + key + '/' + style, 4, Nevermore.settings.quantization);
	}

	public static function findRelativeStyle(skin:Noteskin, style:String, ?force:Bool) {
		var newKey = Path.join([skin.loadKey, "..", style]);
		if (newKey == skin.loadKey)
			return skin;

		return Noteskin.cache.get(newKey, skin.loadKeyCount, skin.alreadyLuminized);
	}

	public static function switchFieldStyle(field:Strumline, style:String, ?force:Bool) {
		var newSkin = findRelativeStyle(field.skin, style);
		if (field.skin == newSkin)
			return;
		var idx = field.field.strumlines.members.indexOf(field);
		field.skin = newSkin;

		for (note in field.field.notes.members) {
			if (note.alive && note.player == idx)
				note.behavior.applySkin(note, NOTE);
		}
		for (hold in field.field.sustains.members) {
			if (hold.alive && hold.player == idx)
				hold.type = hold.type; // Sustain has a setter
		}
	}

	public static function updatePalette() {
		NoteColor.quantList["Custom"] = Settings.data.customQuants;
		NoteColor.list["Custom"] = Settings.data.customColumns; // may become Array<Array> later on

		Nevermore.settings.quantization = Settings.data.quantColouring != "None";
		NoteColor.bySnap = NoteColor.quantList.exists(Settings.data.quantColouring);
		@:privateAccess NoteColor.quantType = NoteColor.bySnap ? Settings.data.quantColouring : CUSTOM;
		@:privateAccess NoteColor.type = CUSTOM;
	}

	public static function getSkinMeta(key:String):NoteskinMeta {
		final defaultColors = [
			[0xFF13FA06], // 1
			[0xFFC24C99, 0xFFF93A40], // 2
			[0xFFC24C99, 0xFF13FA06, 0xFFF93A40], // 3
			[0xFFC24C99, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40], // 4
			[0xFFC24C99, 0xFF02FFFF, 0xFF13FA06, 0xFF13FA06, 0xFFF93A40], // 5
			[0xFFF93A40, 0xFF13FA06, 0xFF02FFFF, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40], // 6
			[0xFFF93A40, 0xFF13FA06, 0xFF02FFFF, 0xFF13FA06, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40], // 7
			[0xFFC24C99, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40, 0xFFF93A40, 0xFF13FA06, 0xFF02FFFF, 0xFFC24C99], // 8
			[0xFFC24C99, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40, 0xFF13FA06, 0xFFF93A40, 0xFF13FA06, 0xFF02FFFF, 0xFFC24C99] // 9				
		];

		if (Assets.exists('skins/$key/meta.json')) {
			var data = Json5.parse(Assets.text('skins/$key/meta.json'));
			var styles:Array<Dynamic> = data.styles ?? [{key: "normal", name: "Normal"}];

			return {
				key: key,
				name: data.displayName ?? key,
				styleKeys: [for (style in styles) style.key],
				styleNames: [for (style in styles) style.key => (style.name ?? style.key)],
				colors: data.colors ?? defaultColors
			};
		}

		return {
			key: key,
			name: key,
			styleKeys: ["normal"],
			styleNames: ["normal" => "Normal"],
			colors: defaultColors
		};
	}

	public static function getList() {
		var map:Map<String, NoteskinMeta> = [];
		var directories:Array<String> = ['assets/skins/'];
		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (addon.enabled)
				directories.push('addons/${addon.directory}/skins/');
		}
		#end

		for (dir in directories) {
			if (!FileSystem.exists(dir))
				continue;

			for (path in FileSystem.readDirectory(dir))
				map.set(path, getSkinMeta(path));
		}
		
		return map;
    }
}