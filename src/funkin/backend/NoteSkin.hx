package funkin.backend;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import funkin.objects.Strumline;
import funkin.backend.ScriptHandler.Script;
import funkin.objects.Strumline.StrumNote;
import funkin.objects.Sustain;
import funkin.objects.Note;

enum abstract NoteSkinStyleType(String) {
	var GRID = "grid";
	var SPARROW = "sparrow";
	// MIGHT make this a thing for if you wanna script your noteskin, prob not useful for camellia but for other things maybe
	var CUSTOM = "custom";
}

@:structInit
class NoteSkinStyle {
	var type: NoteSkinStyleType;
	var name: String;
	@:optional public var displayName: String;

	public function apply(note:Note) {}
	public function applySustain(hold:Sustain) {}
	public function applyStrum(strum:StrumNote, lane:Int) {}

	public function recache() {}
	public function destroy() {}

	public function getScale(obj:FunkinSprite) {return 1.0;}
}

@:structInit
class NoteSkinCustomData extends NoteSkinStyle {
	var data: Dynamic;
	var script: Script;

	public static function interp(obj:Dynamic):NoteSkinCustomData {
		final script = new Script(Paths.get('data/noteSkins/${obj.script}.hx'));
		script.set("data", obj);
		
		script.execute();
		script.call("loaded", [obj]);

		return {
			type: CUSTOM,
			name: obj.name,
			displayName: obj.displayName ?? obj.name,

			data: obj,
			script: script
		}
	}

	override public function apply(note:Note) {script.call("apply", [note]);}
	override public function applySustain(hold:Sustain) {script.call("applySustain", [hold]);}
	override public function applyStrum(strum:StrumNote, lane:Int) {script.call("applyStrum", [strum, lane]);}

	override public function recache() {
		script.call("recache");
	}
	override public function destroy() {
		script.call("destroy");
		script.destroy();
	}

	override public function getScale(obj:FunkinSprite) {
		return script.call("getScale", [obj])?.returnValue ?? 1.0;
	}
}

@:structInit
class NoteSkinGridData extends NoteSkinStyle {
	var frames(get, default):FlxFramesCollection = null;
	var luminFrames(get, default):FlxFramesCollection = null;
	var holdFrames(get, default):FlxFramesCollection = null;
	var luminHoldFrames(get, default):FlxFramesCollection = null;
	var rollFrames(get, default):FlxFramesCollection = null;
	var luminRollFrames(get, default):FlxFramesCollection = null;

	var image: String;
	var holdImage: String;
	@:optional var hasRolls:Bool;
	@:optional var rollImage: String;
	var scale:Float = 6;
	var antialiasing:Bool = false;

	var noteRows: Int = 4;
	var noteColumns: Int = 5;
	var holdRows: Int = 4;
	var holdColumns: Int = 2;
	@:optional var rollRows: Int;
	@:optional var rollColumns: Int;

	var staticIndices: Array<Array<Int>>;
	var noteIndices: Array<Array<Int>>;
	var pressIndices: Array<Array<Int>>;
	var glowIndices: Array<Array<Int>>;
	var holdIndices: Array<Array<Int>>;
	var holdEndIndices: Array<Array<Int>>;
	@:optional var rollIndices: Array<Array<Int>>;
	@:optional var rollEndIndices: Array<Array<Int>>;

	var staticFramerate: Float = 12;
	var noteFramerate: Float = 12;
	var pressFramerate: Float = 12;
	var glowFramerate: Float = 12;
	var holdFramerate: Float = 12;
	var rollFramerate: Float = 12;

	public static function interp(obj:Dynamic):NoteSkinGridData {
		final hasRolls = obj.hasRolls ?? false;
		final holdImg = obj.holdImage ?? obj.image + "ENDS";
		final noteRows = obj.noteRows ?? 4;
		final noteCols = obj.noteColumns ?? 5;
		final holdRows = obj.holdRows ?? 4;
		final holdCols = obj.holdColumns ?? 2;
		final holds = (obj.holdIndices != null && obj.holdIndices.length >= 4) ? obj.holdIndices : [[0], [1], [2], [3]];
		final tails = (obj.holdEndIndices != null && obj.holdEndIndices.length >= 4) ? obj.holdEndIndices : [[4], [5], [6], [7]];

		final staticFPS = obj.staticFramerate ?? 12;
		final noteFPS = obj.noteFramerate ?? staticFPS;
		final holdFPS = obj.holdFramerate ?? noteFPS;
		
		return {
			type: GRID,
			name: obj.name,
			displayName: obj.displayName ?? obj.name,

			image: obj.image,
			holdImage: holdImg,
			hasRolls: hasRolls,
			rollImage: (hasRolls && obj.rollImage != null) ? obj.rollImage : holdImg,
			scale: obj.scale ?? 6.0,
			antialiasing: obj.antialiasing ?? false,

			noteRows: noteRows,
			noteColumns: noteCols,
			holdRows: holdRows,
			holdColumns: holdCols,
			rollRows: (hasRolls && obj.rollRows != null) ? obj.rollRows : holdRows,
			rollColumns: (hasRolls && obj.rollColumns != null) ? obj.rollColumns : holdCols,

			staticIndices: (obj.staticIndices != null && obj.staticIndices.length >= 4) ? obj.staticIndices : [[0], [1], [2], [3]],
			noteIndices: (obj.noteIndices != null && obj.noteIndices.length >= 4) ? obj.noteIndices : [[4], [5], [6], [7]],
			pressIndices: (obj.pressIndices != null && obj.pressIndices.length >= 4) ? obj.pressIndices : [[4, 8], [5, 9], [6, 10], [7, 11]],
			glowIndices: (obj.glowIndices != null && obj.glowIndices.length >= 4) ? obj.glowIndices : [[12, 16], [13, 17], [14, 18], [15, 19]],
			holdIndices: holds,
			holdEndIndices: tails,
			rollIndices: (hasRolls && obj.rollIndices != null && obj.rollIndices.length >= 4) ? obj.rollIndices : holds,
			rollEndIndices: (hasRolls && obj.rollEndIndices != null && obj.rollEndIndices.length >= 4) ? obj.rollEndIndices : tails,

			staticFramerate: staticFPS,
			noteFramerate: noteFPS,
			pressFramerate: obj.pressFramerate ?? staticFPS,
			glowFramerate: obj.glowFramerate ?? staticFPS,
			holdFramerate: holdFPS,
			rollFramerate: (hasRolls && obj.rollFramerate != null) ? obj.rollFramerate : holdFPS
		};
	}

	override public function apply(note:Note) {
		note.antialiasing = antialiasing;
		note.frames = note.luminColors ? luminFrames : frames;
		note.animation.add('default', noteIndices[note.data.lane], noteFramerate);
		note.playAnim('default');

		note.scale.set(scale * Strumline.size, scale * Strumline.size);
		note.updateHitbox();
	}
	override public function applySustain(hold:Sustain) {
		hold.antialiasing = antialiasing;
		if (hasRolls && hold.type == "Roll") {
			hold.frames = hold.luminColors ? luminRollFrames : rollFrames;
			hold.animation.add('hold', rollIndices[hold.data.lane], rollFramerate);
			hold.animation.add('holdend', rollEndIndices[hold.data.lane], rollFramerate);
		} else {
			hold.frames = hold.luminColors ? luminHoldFrames : holdFrames;
			hold.animation.add('hold', holdIndices[hold.data.lane], holdFramerate);
			hold.animation.add('holdend', holdEndIndices[hold.data.lane], holdFramerate);
		}
		hold.scale.set(scale * Strumline.size, scale * Strumline.size);
	}
	override public function applyStrum(strum:StrumNote, lane:Int) {
		strum.antialiasing = antialiasing;
		strum.frames = (Note.curPalette != null || Settings.data.strumGlow == "Judgement") ? luminFrames : frames;

		strum.animation.add('default', staticIndices[lane], staticFramerate);
		strum.animation.add('pressed', pressIndices[lane], pressFramerate, false);
		strum.animation.add('notePressed', glowIndices[lane], glowFramerate, false);
		strum.playAnim('default');

		strum.scale.set(scale * Strumline.size, scale * Strumline.size);
		strum.updateHitbox();
	}

	override public function getScale(obj:FunkinSprite) {return scale;}
	
	override function recache() {
		@:bypassAccessor if (frames != null) {
			frames = null;
			get_frames();
		}
		@:bypassAccessor if (luminFrames != null) {
			luminFrames = null;
			get_luminFrames();
		}
		@:bypassAccessor if (holdFrames != null) {
			holdFrames = null;
			get_holdFrames();
		}
		@:bypassAccessor if (luminHoldFrames != null) {
			luminHoldFrames = null;
			get_luminHoldFrames();
		}
		@:bypassAccessor if (rollFrames != null) {
			rollFrames = null;
			get_rollFrames();
		}
		@:bypassAccessor if (luminRollFrames != null) {
			luminRollFrames = null;
			get_luminRollFrames();
		}
	}

	function get_frames() {
		if (frames != null)
			return frames;
		final img = Paths.image("noteSkins/" + Note.getTextureKey(image, false, ".png"));
		return frames = FlxTileFrames.fromGraphic(img, FlxPoint.weak(Math.floor(img.width / noteRows), Math.floor(img.height / noteColumns)));
	}
	function get_luminFrames() {
		if (luminFrames != null)
			return luminFrames;
		final img = Paths.image("noteSkins/" + Note.getTextureKey(image, true, ".png"));
		return luminFrames = FlxTileFrames.fromGraphic(img, FlxPoint.weak(Math.floor(img.width / noteRows), Math.floor(img.height / noteColumns)));
	}
	
	function get_holdFrames() {
		if (holdFrames != null)
			return holdFrames;
		final img = Paths.image("noteSkins/" + Note.getTextureKey(holdImage, false, ".png"));
		return holdFrames = FlxTileFrames.fromGraphic(img, FlxPoint.weak(Math.floor(img.width / holdRows), Math.floor(img.height / holdColumns)));
	}
	function get_luminHoldFrames() {
		if (luminHoldFrames != null)
			return luminHoldFrames;
		final img = Paths.image("noteSkins/" + Note.getTextureKey(holdImage, true, ".png"));
		return luminHoldFrames = FlxTileFrames.fromGraphic(img, FlxPoint.weak(Math.floor(img.width / holdRows), Math.floor(img.height / holdColumns)));
	}

	function get_rollFrames() {
		if (rollFrames != null)
			return rollFrames;
		final img = Paths.image("noteSkins/" + Note.getTextureKey(rollImage, false, ".png"));
		return rollFrames = FlxTileFrames.fromGraphic(img, FlxPoint.weak(Math.floor(img.width / rollRows), Math.floor(img.height / rollColumns)));
	}
	function get_luminRollFrames() {
		if (luminRollFrames != null)
			return luminRollFrames;
		final img = Paths.image("noteSkins/" + Note.getTextureKey(rollImage, true, ".png"));
		return luminRollFrames = FlxTileFrames.fromGraphic(img, FlxPoint.weak(Math.floor(img.width / rollRows), Math.floor(img.height / rollColumns)));
	}
}

@:structInit
class NoteSkinSparrowData extends NoteSkinStyle {
	var frames(get, default):FlxFramesCollection = null;
	var luminFrames(get, default):FlxFramesCollection = null;

	var image: String;
	var scale:Float = 0.65;
	var antialiasing:Bool = true;

	var noteAnims: Array<String> = [for (col in Note.colours) col + "0"];
	var holdAnims: Array<String> = [for (col in Note.colours) col + " hold piece"];
	var holdEndAnims: Array<String> = [for (col in Note.colours) col + " hold end"];
	var rollAnims: Array<String> = [for (col in Note.colours) col + " roll piece"];
	var rollEndAnims: Array<String> = [for (col in Note.colours) col + " roll end"];
	var staticPrefixes: Array<String> = [for (dir in Note.directions) "arrow" + dir.toUpperCase()];
	var pressPrefixes: Array<String> = [for (dir in Note.directions) dir + " press"];
	var glowPrefixes: Array<String> = [for (dir in Note.directions) dir + " confirm"];

	var staticFramerate: Float = 24;
	var noteFramerate: Float = 24;
	var pressFramerate: Float = 24;
	var glowFramerate: Float = 24;
	var holdFramerate: Float = 24;
	var rollFramerate: Float = 24;

	public static function interp(obj:Dynamic):NoteSkinSparrowData {
		final staticFPS = obj.staticFramerate ?? 24;
		final noteFPS = obj.noteFramerate ?? staticFPS;
		final holdFPS = obj.holdFramerate ?? noteFPS;
		
		return {
			type: SPARROW,
			name: obj.name,
			displayName: obj.displayName ?? obj.name,

			image: obj.image,
			scale: obj.scale ?? 0.65,
			antialiasing: obj.antialiasing ?? true,

			noteAnims: (obj.noteAnims != null && obj.noteAnims.length >= 4) ? obj.noteAnims : [for (col in Note.colours) col + "0"],
			holdAnims: (obj.holdAnims != null && obj.holdAnims.length >= 4) ? obj.holdAnims : [for (col in Note.colours) col + " hold piece"],
			holdEndAnims: (obj.holdEndAnims != null && obj.holdEndAnims.length >= 4) ? obj.holdEndAnims : [for (col in Note.colours) col + " hold end"],
			rollAnims: (obj.rollAnims != null && obj.rollAnims.length >= 4) ? obj.rollAnims : [for (col in Note.colours) col + " roll piece"],
			rollEndAnims: (obj.rollEndAnims != null && obj.rollEndAnims.length >= 4) ? obj.rollEndAnims : [for (col in Note.colours) col + " roll end"],
			staticPrefixes: (obj.staticPrefixes != null && obj.staticPrefixes.length >= 4) ? obj.staticPrefixes : [for (dir in Note.directions) "arrow" + dir.toUpperCase()],
			pressPrefixes: (obj.pressPrefixes != null && obj.pressPrefixes.length >= 4) ? obj.pressPrefixes : [for (dir in Note.directions) dir + " press"],
			glowPrefixes: (obj.glowPrefixes != null && obj.glowPrefixes.length >= 4) ? obj.glowPrefixes : [for (dir in Note.directions) dir + " confirm"],

			staticFramerate: staticFPS,
			noteFramerate: noteFPS,
			pressFramerate: obj.pressFramerate ?? staticFPS,
			glowFramerate: obj.glowFramerate ?? staticFPS,
			holdFramerate: holdFPS,
			rollFramerate: obj.rollFramerate ?? holdFPS
		};
	}

	override public function apply(note:Note) {
		note.antialiasing = antialiasing;
		note.frames = (note.luminColors) ? luminFrames : frames;

		note.animation.addByPrefix('default', noteAnims[note.data.lane], noteFramerate);
		note.playAnim('default');

		note.scale.set(scale * Strumline.size, scale * Strumline.size);
		note.updateHitbox();
	}
	override public function applySustain(hold:Sustain) {
		hold.antialiasing = antialiasing;
		final isRoll = hold.type == "Roll";
		final anims = isRoll ? rollAnims : holdAnims;
		final endAnims = isRoll ? rollEndAnims : holdEndAnims;
		final fps = isRoll ? rollFramerate : holdFramerate;

		hold.frames = (hold.luminColors) ? luminFrames : frames;

		hold.animation.addByPrefix('hold', anims[hold.data.lane], fps);
		hold.animation.addByPrefix('holdend', endAnims[hold.data.lane], fps);
		hold.scale.set(scale * Strumline.size, scale * Strumline.size);
	}
	override public function applyStrum(strum:StrumNote, lane:Int) {
		strum.antialiasing = antialiasing;
		strum.frames = (Note.curPalette != null || Settings.data.strumGlow == "Judgement") ? luminFrames : frames;

		strum.animation.addByPrefix('default', staticPrefixes[lane], staticFramerate);
		strum.animation.addByPrefix('pressed', pressPrefixes[lane], pressFramerate, false);
		strum.animation.addByPrefix('notePressed', glowPrefixes[lane], glowFramerate, false);
		strum.playAnim('default');

		strum.scale.set(scale * Strumline.size, scale * Strumline.size);
		strum.updateHitbox();
	}
	
	override public function getScale(obj:FunkinSprite) {return scale;}
	
	override function recache() {
		@:bypassAccessor if (frames != null) {
			frames = null;
			get_frames();
		}
		@:bypassAccessor if (luminFrames != null) {
			luminFrames = null;
			get_luminFrames();
		}
	}

	function get_frames() {
		if (frames != null)
			return frames;
		return frames = Paths.sparrowAtlas("noteSkins/" + Note.getTextureKey(image, false, ".xml"));
	}
	function get_luminFrames() {
		if (luminFrames != null)
			return luminFrames;
		return luminFrames = Paths.sparrowAtlas("noteSkins/" + Note.getTextureKey(image, true, ".xml"));
	}
}

class NoteSkin {
	public static var _cache:Map<String, NoteSkin> = [];

	public var displayName: String = 'Fallback';
	public var styles:Map<String, NoteSkinStyle> = [];
	public var styleOrder:Array<String> = [];

	public function new(displayName:String) {this.displayName = displayName;}

	public function getStyle(style:String) {
		return styles.exists(style) ? styles[style] : styles["normal"];
	}

	public static function get(skin:String):NoteSkin {
		if (_cache.exists(skin))
			return _cache.get(skin);

		var file:NoteSkin = new NoteSkin(skin);

		var fileContent:String = Paths.getFileContent('data/noteSkins/$skin.json5');
		if (fileContent == '') fileContent = Paths.getFileContent('data/noteSkins/$skin.json');
		if (fileContent == '') {
			final backupData:NoteSkinSparrowData = {
				type: SPARROW,
				name: "normal",
				displayName: "Normal",
				image: skin
			};
			file.styles.set("normal", backupData);
			file.styleOrder = ["normal"];
			return file;
		}

		var dataFile = Json5.parse(fileContent);
		if (dataFile.displayName != null)
			file.displayName = dataFile.displayName;

		if (dataFile.styles != null && dataFile.styles.length > 0) {
			final list:Array<Dynamic> = cast dataFile.styles;
			for (style in list) {
				file.styleOrder.push(style.name);
				file.styles.set(style.name, switch (style.type.toLowerCase()) {
					case "custom": NoteSkinCustomData.interp(style);
					case "grid": NoteSkinGridData.interp(style);
					default: NoteSkinSparrowData.interp(style);
				});
			}

			if (!file.styleOrder.contains("normal")) {
				file.styles.set("normal", file.styles[file.styleOrder[0]]);
				file.styleOrder.unshift("normal");
			}
		} else {
			final backupData:NoteSkinSparrowData = {
				type: SPARROW,
				name: "normal",
				displayName: "Normal",
				image: skin
			};
			file.styles.set("normal", backupData);
			file.styleOrder = ["normal"];
		}
		_cache.set(skin, file);
		return file;
	}

	public static function recache() {
		for (file in _cache) {
			for (style in file.styles)
				style.recache();
		}
	}
	public static function clear() {
		for (file in _cache) {
			for (style in file.styles)
				style.destroy();
		}

		_cache.clear();
	}
}