package funkin.backend;

@:structInit
class Judgement {
	public static var list:Array<Judgement>;

	public static var max(get, never):Judgement;
	static function get_max():Judgement return list[list.length - 1];

	public static var min(get, never):Judgement;
	static function get_min():Judgement return list[0];

	public var name:String;
	public var shortName:String;
	public var timing(get, default):Float;
	function get_timing():Float return timing * FlxG.timeScale;
	public var accuracy:Float = 0.0;
	public var health:Float = 0.0;
	public var breakCombo:Bool = false;
	public var color:FlxColor = FlxColor.TRANSPARENT;
	public var splashes:Bool = false;

	public var hits:Int = 0;

	public static function getIDFromTiming(noteDev:Float):Int {
		var value:Int = list.length - 1;

		for (i in 0...list.length) {
			if (Math.abs(noteDev) > list[i].timing) continue;
			value = i;
			break;
		}

		return value;
	}

	public static function getFromTiming(noteDev:Float):Judgement {
		var judge:Judgement = max;

		for (possibleJudge in list) {
			if (Math.abs(noteDev) > possibleJudge.timing) continue;
			judge = possibleJudge;
			break;
		}

		return judge;
	}
	
	inline public static function reset():Void {
		list = [
			{
				name: 'sick',
				shortName: "SK",
				timing: 45,
				accuracy: 100,
				health: 2.5,
				splashes: true,
				color: 0xFF2CEDFF
			},
			{
				name: 'good',
				shortName: "GD",
				timing: 90,
				accuracy: 85,
				health: 1,
				color: 0xFF43FF2E
			},
			{
				name: 'bad',
				shortName: "BD",
				timing: 135,
				accuracy: 45,
				health: -6,
				color: 0xFFFF8F34
			},
			{
				name: 'shit',
				shortName: "SH",
				timing: 180,
				accuracy: 30,
				health: -10,
				breakCombo: true,
				color: 0xFFFF2533
			}
		];
	}

	public function toString():String {
		return 'Judgement | Name: "$name" | Timing: ${timing / FlxG.timeScale}';
	}
}