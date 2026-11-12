package funkin.core;

typedef Translation = {
	var id:String;
	var text:String;
}

typedef LocaleFile = {
	var name:String;
	var translations:Array<Translation>;
}

class Languages {
	public static var initialized:Bool = false;
	public static var list:Array<Locale> = [];
	public static var current:Locale;

	public static function init() {
		if (initialized) return;
		initialized = true;

		// gonna do a folder check later but just for now
		list = [
			new Locale('en-US'),
			new Locale('pt-BR'),
			new Locale('es-ES'),
			new Locale('jp-JP')
		];

		Sys.println('Translations loaded!');
		for (locale in list) {
			Sys.println(locale);
		}
		Sys.println('');
	}

	public static function reset(localeID:String = '') {
		current = getByID(localeID);
	}

	public static function getByID(id:String):Locale {
		for (locale in list) {
			if (locale.id == id) return locale;
		}

		return null;
	}

	public static function getText(id:String, ?replace:Array<Dynamic>):String {
		replace ??= [];
		return current.translations[id];
	}
}

class Locale {
	public var name:String;
	public var id:String;

	public var translations:Map<String, String> = [];

	public function new(id:String) {
		this.id = id;

		var file:LocaleFile = getDummyFile();
		if (Assets.exists('data/locale/$id')) {
			var meta:LocaleFile = cast Json5.parse(Assets.text('data/locale/$id/meta.json'));
			file.name = meta.name;

			meta.translations ??= [];
			// because haxe
			var translations:Array<Translation> = [];
			for (fuck in meta.translations) {
				translations.push({id: fuck.id, text: fuck.text});
			}

			file.translations = translations;
		}
		
		name = file.name;
		for (translation in file.translations) {
			translations.set(translation.id, translation.text);
		}
	}

	public static function getDummyFile():LocaleFile {
		return {
			name: 'Unknown (???)',
			translations: []
		}
	}

	public function toString():String {
		return '$id | $name';
	}
}