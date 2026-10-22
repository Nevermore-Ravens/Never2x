package funkin.objects;

import nevermore.play.*;
import nevermore.skins.Noteskin;
import nevermore.skins.BasicNoteskin;
import nevermore.skins.NoteskinSection;

class NoteSplash extends NoteObject {
	//public static var possibleNotesplashes: Array<String> = ['none']; // idk maybe we move this some day lmao
	//public static var notesplashNames: Map<String, String> = ['none' => 'None'];

	private static var loader:Noteskin = new Noteskin({}); // shhhhhhhhhhhhhh

	public static function getSplash(from:Receptor) {
		for (attach in from.attachments) {
			if (!Std.isOfType(attach, NoteSplash) || attach.exists)
				continue;

			attach.revive();
			return cast attach;
		}

		var attach = new NoteSplash(from.lane);
		from.attachments.push(attach);
		return attach;
	}

	/// oooooooooooohhhhhh i do not like this -srt, the damn guy who made this shit
	// its just, messy
	public static function getData(key:String, keyCount:Int, ?luminized:Bool = false):NoteskinSection<Dynamic> {
		var mapKey = Noteskin.cache.getMapKey(key, keyCount, luminized); 
		if (loader.sections.exists(mapKey))
			return loader.sections.get(mapKey);

		inline function getLoadKey(tryLumin:Bool)
			return 'images/noteSplashes/' + (tryLumin ? key + "-luminized" : key);
		inline function createSection(from:Dynamic) {
			var sect = NoteskinSection.create(loader, from);
			loader.sections.set(mapKey, sect);
			return sect;
		}
		
		var attempts = luminized ? 2 : 1;
		for (i in 0...attempts) {
			var loadKey = getLoadKey(luminized && i == 0);
			var jsonPath = loadKey + ".json";
			if (Assets.exists(jsonPath)) {
				try {
					var json = haxe.Json.parse(Assets.text(jsonPath));
					return createSection(json);
				} catch (e) {}
			}
		}

		var colors = [for (idx in BasicNoteskin.directionList[keyCount - 1]) Note.colors[idx]];
		inline function makeBasic(key) {
			return createSection({
				style: "sparrow",
				spritesheet: key,
				animations: [
					{
						name: "splash1",
						prefixes: [for (col in colors) 'note splash ${col} 1']
					},
					{
						name: "splash2",
						prefixes: [for (col in colors) 'note splash ${col} 2']
					}
				]
			});
		}

		if (luminized) {
			var loadKey = getLoadKey(true);
			if (Assets.exists(loadKey + ".xml"))
				return makeBasic(loadKey);
		}

		return makeBasic(getLoadKey(false));
	}

	public function new(lane:Int) {
		super();
		this.lane = lane;
		moves = false;
		alpha = 0.6;

		animation.finishCallback = function(_) {
			kill();
		}
	}

	public function hit(receptor:Receptor) {
		revive();
		alpha = 0.6;

		luminize = receptor.luminize;
		color = receptor.color;

		var data = getData(Settings.data.noteSplashSkin, receptor.parent.keyCount, receptor.luminize);
		data.applyNoteObject(this);
		scale.scale(receptor.parent.size * receptor.parent.keyScale);
		animation.play(FlxG.random.getObject(data.animations).name, true);
		updateHitbox();
	}
}