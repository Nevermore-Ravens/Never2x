package funkin.core;

import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimateFrames;
import flixel.util.typeLimit.OneOfTwo;

class FunkinAssets {
	static function applySubFolder(key:String, ?subFolder:String = ''):String {
		if (subFolder.length != 0) key = subFolder + '/' + key;
		return key;
	}

	static function getPath(key:String, ?subFolder:String = ''):String {
		return Assets.getPath(applySubFolder(key, subFolder));
	}

	public static dynamic function animateAtlas(path:String, ?subFolder:String = 'images'):FlxAnimateFrames {
		var frames = FlxAnimateFrames.fromAnimate(getPath(path, subFolder));
		frames.parent.persist = true;
		return frames;
	}

	// we don't want to overcombine.
	static function combineAtlas(atlasA:FlxAtlasFrames, atlasB:FlxAtlasFrames):FlxAtlasFrames {
		if (atlasA is FlxAnimateFrames) {
			@:privateAccess if (atlasB is FlxAnimateFrames && cast (atlasA, FlxAnimateFrames).addedCollections.contains(cast atlasB))
				return atlasA;
			return atlasA.addAtlas(atlasB, false);
		}

		@:privateAccess if (atlasA is FlxAnimateFrames && cast (atlasB, FlxAnimateFrames).addedCollections.contains(cast atlasA))
			return atlasB;
		return atlasB.addAtlas(atlasA, false);
	}

	public static function multiAtlas(keys:Array<String>, ?subFolder:String = 'images'):Dynamic {
		function getFrames(key:String):OneOfTwo<FlxAtlasFrames, FlxAnimateFrames> {
			var frames:OneOfTwo<FlxAtlasFrames, FlxAnimateFrames> = null;
			var path:String = applySubFolder(key, subFolder);
			if (Assets.exists('$path/Animation.json')) frames = cast animateAtlas(key, subFolder);
			else frames = cast Assets.sparrowAtlas(path);

			return frames;
		}

		var parentFrames = cast getFrames(keys[0]);
		if (keys.length == 1) return parentFrames;

		if (parentFrames == null) return null;

		for (i in 1...keys.length) {
			var extraFrames = cast getFrames(keys[i]);
			if (extraFrames == null) continue;
			parentFrames = combineAtlas(parentFrames, extraFrames);
		}
		
		return parentFrames;
	}
}