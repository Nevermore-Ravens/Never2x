package funkin.objects;

import funkin.objects.Character;

enum abstract StageObjType(String) {
	var SPRITE;
	var GROUP;
	var SPECTATOR;
	var ENEMY;
	var PLAYER;
	var CHARACTER; // general positions, for if it's dedicated to like a special script character
}

typedef StageFile = {
	var ?zoom:Float;
	var ?cameraPos:Array<Float>;
	var ?canMoveCamera:Bool;

	var objects:Array<StageObject>;
}

typedef StageObject = {
	var name:String;
	var type:StageObjType;

	var pos:Array<Float>;
	var ?scale:Array<Float>;
	var ?scroll:Array<Float>;
	var ?alpha:Float;

	// sprite specific
	var ?sheets:String;
	var ?antialiasing:Bool;
	var ?animations:Array<FunkinAnimData>;
	var ?flipX:Bool;
	var ?flipY:Bool;

	// group specific
	var ?objects:Array<StageObject>;

	// character specific
	var ?reflective:Bool;
	var ?facesLeft:Bool;
	var ?legacyPositioning:Bool;
	var ?cameraOffset:Array<Float>;
}

class CharacterPos extends FunkinSpriteGroup<Character> {
	public var cameraOffset:FlxPoint;
	public var facesLeft:Bool = false;
	public var reflective:Bool = false;
	public var legacyPositioning:Bool = true; // true for now

	override function preAdd(char:Character) {
		char.cameraOffset.add(cameraOffset.x, cameraOffset.y);
		char.facingLeft = facesLeft;
		char.reflective = reflective;
		if (!legacyPositioning)
			char.setPosition(char.x - char.width * 0.5, char.y - char.height);
		super.preAdd(char);
	}
	override function remove(char:Character, splice:Bool = false) {
		char.cameraOffset.subtract(cameraOffset.x, cameraOffset.y);
		var result = super.remove(char, splice);
		if (!legacyPositioning)
			char.setPosition(char.x + char.width * 0.5, char.y + char.height);
		return result;
	}

	override function initVars() {
		super.initVars();
		cameraOffset = FlxPoint.get(0, 0);
	}
	override function destroy() {
		super.destroy();
		cameraOffset = flixel.util.FlxDestroyUtil.put(cameraOffset);
	}
}
class Stage extends FunkinSpriteGroup {
	var _file:StageFile;
	public var name:String;

	public var zoom:Float = 1;
	public var canMoveCamera:Bool = false;
	public var cameraPos:FlxPoint;

	public var spectatorPos(get, default):CharacterPos;
	public var enemyPos(get, default):CharacterPos;
	public var playerPos(get, default):CharacterPos;

	public var objectMap:Map<String, FlxSprite> = [];

	public function new(name:String) {
		super();
		this.name = name;

		_file = getFile('stages/$name.json');
		zoom = _file.zoom;
		cameraPos.set(_file.cameraPos[0], _file.cameraPos[1]);
		canMoveCamera = _file.canMoveCamera;

		for (obj in _file.objects)
			loadObject(obj, this);
	}

	public function loadObject(data:StageObject, to:FunkinSpriteGroup) {
		var obj:FlxSprite = switch (data.type) {
			case GROUP:
				new FunkinSpriteGroup();
			case SPECTATOR:
				spectatorPos;
			case ENEMY:
				enemyPos;
			case PLAYER:
				playerPos;
			case CHARACTER:
				new CharacterPos();
			default:
				var spr = new FunkinSprite();
				spr.flipX = data.flipX == true;
				spr.flipY = data.flipY == true;

				if (data.animations == null || data.animations.length <= 0)
					spr.loadGraphic(Assets.image("images/" + data.sheets));
				else {
					spr.frames = FunkinAssets.multiAtlas(data.sheets.split(","));
					for (anim in (data.animations ?? []))
						spr.makeAnimFromData(anim);
				}
				spr;
		}

		var scale = data.scale ?? [1.0, 1.0];
		var scroll = data.scroll ?? [1.0, 1.0];
		obj.setPosition(data.pos[0], data.pos[1]);
		obj.scale.set(scale[0], scale[1]);
		obj.scrollFactor.set(scroll[0], scroll[1]);
		obj.alpha = data.alpha ?? 1;

		objectMap.set(data.name, obj);
		to.add(obj);
		switch (data.type) {
			case GROUP:
				var grp:FunkinSpriteGroup = cast obj;
				for (child in (data.objects ?? []))
					loadObject(child, grp); // better to load after transformations for less iterations
			case SPECTATOR | ENEMY | PLAYER | CHARACTER:
				var pos:CharacterPos = cast obj;
				var camera = data.cameraOffset ?? [0.0, 0.0];

				pos.cameraOffset.set(camera[0], camera[1]);
				pos.facesLeft = data.facesLeft ?? (data.type == PLAYER);
				pos.reflective = data.reflective == true;
				pos.legacyPositioning = data.legacyPositioning != false; // default true for now
			default:
				obj.updateHitbox();
				obj.antialiasing = data.antialiasing != false;
		}
	}

	public function hasSpectatorPos()
		@:bypassAccessor return spectatorPos != null;
	function get_spectatorPos() {
		if (spectatorPos == null)
			spectatorPos = new CharacterPos();
		return spectatorPos;
	}

	public function hasEnemyPos()
		@:bypassAccessor return enemyPos != null;
	function get_enemyPos() {
		if (enemyPos == null)
			enemyPos = new CharacterPos();
		return enemyPos;
	}

	public function hasPlayerPos()
		@:bypassAccessor return playerPos != null;
	function get_playerPos() {
		if (playerPos == null)
			playerPos = new CharacterPos();
		return playerPos;
	}

	override function initVars() {
		super.initVars();
		cameraPos = FlxPoint.get(0, 0);
	}
	override function destroy() {
		super.destroy();
		cameraPos = flixel.util.FlxDestroyUtil.put(cameraPos);
		objectMap.clear();
	}

	public static function getFile(path:String):StageFile {
		var file:StageFile = createDummyFile();
		if (!Assets.exists(path)) return file;
		
		var data = Json5.parse(Assets.text(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}

	public static function createDummyFile():StageFile {
		return {
			zoom: 1,
			cameraPos: [0, 0],
			canMoveCamera: true,

			objects: [
				{
					name: "spectatorPos",
					type: SPECTATOR,
					pos: [400, 130]
				},
				{
					name: "enemyPos",
					type: ENEMY,
					pos: [100, 100]
				},
				{
					name: "playerPos",
					type: PLAYER,
					pos: [770, 100]
				}
			]
		}
	}
}