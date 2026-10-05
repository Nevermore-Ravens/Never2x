package funkin.backend;

@:structInit
@:publicFields
class WeekFile {
	var songs:Array<SongData> = [];
	var weekNum:String = '';
	var name:String = '';
	var background:String = '';
	var folder:String = '';
	var fileName:String = ''; 
	var difficulties:Array<String> = Difficulty.default_list;
}

@:structInit
@:publicFields
class SongData {
	var id:String = '';
	var color:FlxColor = 0xFFFFFFFF;
	var icon:String = 'face';
	var difficulties:Array<String> = [];
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

		var directories:Array<String> = ['assets'];
		var originalLength:Int = directories.length;
		
		#if ADDONS_ALLOWED
		for (addon in Addons.list) {
			if (addon.enabled)
				directories.push('addons/${addon.directory}');
		}
		#end

		for (i => path in directories) {
			if (!FileSystem.exists('$path/weeks')) continue;

			for (week in FileSystem.readDirectory('$path/weeks')) {
				var file:WeekFile = getFile('$path/weeks/$week');
				file.fileName = week.replace('.json', '');
				if (i >= originalLength) file.folder = path;
				
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
			if (property == 'songs' || property == 'file' || property == 'fileName') continue;

			Reflect.setField(file, property, Reflect.field(data, property));
		}

		// god i hate haxe sometimes
		var songs:Array<{id:String, color:FlxColor, icon:String, difficulties:Array<String>}> = data.songs;
		for (song in songs) {
			file.songs.push({
				id: song.id,
				color: song.color,
				icon: song.icon,
				difficulties: song.difficulties
			});
		}

		return file;
	}
}