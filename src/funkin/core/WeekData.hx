package funkin.core;

@:structInit
@:publicFields
class WeekFile {
	var songs:Array<SongData> = [];
	var weekNum:String = '';
	var name:String = '';
	var background:String = '';
	var fileName:String = ''; 
	var difficulties:Array<DiffData> = Difficulty.loadDynamic(null);

	var from:Addon = null;
}

@:structInit
@:publicFields
class SongData {
	var id:String = '';
	var color:FlxColor = 0xFFFFFFFF;
	var icon:String = 'face';
	var difficulties:Array<DiffData> = [];
}

class WeekData {
	public static var list:Array<WeekFile> = [];
	public static var current:Int = 0;

	public static function createDummyFile():WeekFile {
		return {
			songs: [],
			
			name: 'Week',
			background: 'default',
		}
	}

	public static function reload() {
		list.resize(0);

		var addons:Array<Addon> = [null];
		var directories:Array<String> = ['assets'];
		var originalLength:Int = directories.length;
		
		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (!addon.enabled) continue;
			directories.push('addons/${addon.directory}');
			addons.push(addon);
		}
		#end

		for (i => path in directories) {
			if (!FileSystem.exists('$path/weeks')) continue;

			for (week in FileSystem.readDirectory('$path/weeks')) {
				var file:WeekFile = getFile('$path/weeks/$week');
				file.fileName = week.replace('.json', '');
				file.from = addons[i];
				
				list.push(file);
				if (file.weekNum == "") file.weekNum = Std.string(list.length);
			}
		}
	}

	public static function getFile(path:String):WeekFile {
		var file:WeekFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.fields(file).contains(property)) continue;
			if (property == 'songs' || property == 'difficulties' || property == 'file' || property == 'fileName') continue;

			Reflect.setField(file, property, Reflect.field(data, property));
		}
		file.difficulties = Difficulty.loadDynamic(data.difficulties);

		// god i hate haxe sometimes
		var songs:Array<{id:String, color:FlxColor, icon:String, difficulties:Dynamic}> = data.songs;
		for (song in songs) {
			file.songs.push({
				id: song.id,
				color: song.color,
				icon: song.icon,
				difficulties: song.difficulties == null ? null : Difficulty.loadDynamic(song.difficulties, file.difficulties)
			});
		}

		return file;
	}
}