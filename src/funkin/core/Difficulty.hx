package funkin.core;

typedef DiffData = {
	var name:String;
	var color:FlxColor;
}

class Difficulty {
	public static final default_colors:Array<FlxColor> = [0xFF2CF75F, 0xFFFFD500, 0xFFF05825];
	public static final default_list:Array<String> = ['Easy', 'Normal', 'Hard'];
	public static final default_current:String = 'Normal';

	public static var list:Array<String> = default_list.copy();
	public static var colors:Array<FlxColor> = default_colors.copy();
	public static var current:String = default_current;
	public static var currentColor(get, never):FlxColor;

	// just a `Util.format` wrapper for `Difficulty.current`
	inline public static function format(?name:String):String {
		return Util.format(name ?? current);
	}

	public static function loadFromWeek(week:WeekFile):Array<DiffData> {
		var diffs:Array<DiffData> = week.difficulties;
		var defaultResult:Array<DiffData> = [for (i in 0...default_list.length) {name: default_list[i], color: default_colors[i]}];
		if (diffs == null || diffs.length == 0) return defaultResult;

		var i:Int = diffs.length - 1;
		while (i > 0) {
			var diff:DiffData = diffs[i];
			if (diff == null) {
				--i;
				continue;
			}

			diff.name = diff.name.trim();
			if (diff.name.length < 1) diffs.remove(diff);
			--i;
		}

		if (diffs.length > 0 && diffs[0].name.length > 0) return diffs;
		return defaultResult;
	}

	inline public static function reset() {
		list = default_list.copy();
		colors = default_colors.copy();
		current = default_current;
	}

	public static function loadDynamic(?val:Array<Dynamic>, ?backup:Array<DiffData>) {
		var result:Array<DiffData> = [];
		var defaultResult:Array<DiffData> = backup ?? [for (i in 0...default_list.length) {name: default_list[i], color: default_colors[i]}];
		if (val == null)
			return defaultResult;

		for (diff in val) {
			if (diff is String) {
				result.push({
					name: diff,
					color: 0xFFFFFFFF
				});
				continue;
			}
			if (diff is Int) {
				result.push({
					name: default_list[diff],
					color: default_colors[diff]
				});
				continue;
			}
			if (Reflect.isObject(diff)) {
				result.push({
					name: diff.name ?? "um",
					color: diff.color ?? 0xFFFFFFFF
				});
			}
		}

		if (result.length > 0 && result[0].name.length > 0) return result;
		return defaultResult;
	}

	static function get_currentColor() {
		var idx:Int = list.indexOf(current);
		return (idx < 0 || idx >= colors.length) ? 0xFFFFFFFF : colors[idx];
	}
}