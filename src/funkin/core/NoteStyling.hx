package funkin.core;

import nevermore.play.Strumline;
import nevermore.skins.Noteskin;
import haxe.io.Path;

class NoteStyling {
	public static function getSkinAndStyle(key:String, style:String) {
		return Noteskin.get('skins/' + key + '/' + style);
	}

	public static function findRelativeStyle(skin:Noteskin, style:String) {
		var newKey = Path.join([skin.loadKey, "..", style]);
		if (newKey == skin.loadKey)
			return skin;

		return Noteskin.cache.get(newKey, skin.loadKeyCount, skin.alreadyLuminized);
	}

	public static function switchFieldStyle(field:Strumline, style:String) {
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
}