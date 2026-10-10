package funkin.objects;

import nevermore.play.*;
import nevermore.skins.Noteskin;
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
	public static function getData(key:String, ?quants:Bool = false):NoteskinSection<Dynamic> {
		var mapKey = quants ? key + "-quant" : key; 
		if (loader.sections.exists(mapKey))
			return loader.sections.get(mapKey);

		inline function getLoadKey(tryQuants:Bool)
			return 'images/noteSplashes/' + (#if !NEVERMORE_NO_QUANTIZATION tryQuants ? key + '-quant' : #end key);
		inline function createSection(from:Dynamic) {
			var sect = NoteskinSection.create(loader, from);
			loader.sections.set(mapKey, sect);
			return sect;
		}
		
		var preferQuants = quants;
		var attempts = quants ? 2 : 1;
		for (i in 0...attempts) {
			var loadKey = getLoadKey(quants);
			var jsonPath = loadKey + ".json";
			if (Assets.exists(jsonPath)) {
				try {
					var json = haxe.Json.parse(Assets.text(jsonPath));
					return createSection(json);
				} catch (e) {
					quants = false;
				}
			} else
				quants = false;
		}

		inline function makeBasic(key) {
			return createSection({
				style: "sparrow",
				spritesheet: key,
				animations: [
					{
						name: "splash1",
						prefixes: [for (col in Note.colors) 'note splash ${col} 1']
					},
					{
						name: "splash2",
						prefixes: [for (col in Note.colors) 'note splash ${col} 2']
					}
				]
			});
		}

		if (preferQuants) {
			var loadKey = getLoadKey(true);
			if (!quants || Assets.exists(loadKey + ".xml"))
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

		var data = getData(Settings.data.noteSplashSkin, receptor.luminize);
		data.apply(this, loader.supportsXKeys ? lane : lane % 4);
		scale.scale(receptor.parent.size * receptor.parent.keyScale);
		animation.play(FlxG.random.getObject(data.animations).name, true);
		updateHitbox();
	}
}