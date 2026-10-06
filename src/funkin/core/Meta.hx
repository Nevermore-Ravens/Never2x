package funkin.core;

import nevermore.core.timing.TimingPoint;

@:structInit
class MetaFile {
	public var songName:String = 'Unknown';
	public var timingPoints:Array<TimingPoint> = [];
	public var offset:Float = 0.0;
	public var hasVocals:Bool = true;
	public var hasModchart:Bool = false;

	public var player:String = 'bf';
	public var spectator:String = 'bf';
	public var opponent:String = 'bf';
	public var stage:String = 'stage';
}

typedef MetaTimingPoint = {
	var time:Float;
	var ?tempo:Float;
	var ?beatsPerMeasure:Int;
}

class Meta {
	static var _cache:Map<String, MetaFile> = [];
	public static function cacheFiles(?force:Bool = false):Void {
		if (force) _cache.clear();

		var directories:Array<String> = ['assets'];

		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (addon.enabled)
				directories.push('addons/${addon.directory}');
		}
		#end

		for (i => path in directories) {
			if (!FileSystem.exists('$path/songs')) continue;

			for (song in FileSystem.readDirectory('$path/songs')) {
				_cache.set(song, load(song));
			}
		}
	}

	public static function load(song:String):MetaFile {
		if (_cache.exists(song)) return _cache[song];
		
		var path:String = 'songs/$song/meta.json';
		var file:MetaFile = {};
		file.songName = song;

		// still keeping this check here
		// in case the file isn't in the cache
		// but the user wants to parse it anyways
		if (!Assets.exists(path)) return file;
		var data:Dynamic = Json5.parse(Assets.text(path));

		if (data.enemy != null)
			file.opponent = data.enemy;

		for (property in Reflect.fields(data)) {
			// ??????? ok i guess no `Reflect.hasField()` for you
			if (!Reflect.fields(file).contains(property)) continue;
			if (property == 'timingPoints') continue;
			
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		// have to do it this way
		// otherwise haxe shits itself and starts printing insane numbers
		// and that's no good /ref
		var timingPoints:Array<MetaTimingPoint> = data.timingPoints;
		if (timingPoints != null) {
			for (point in timingPoints) {
				file.timingPoints.push({
					time: point.time,
					tempo: point.tempo ?? 0,
					beatsPerMeasure: point.beatsPerMeasure ?? 4
				});
			}
		}
		_cache.set(song, file);
		return file;
	}
}