package funkin.objects;

import flixel.graphics.FlxGraphic;

class CharIcon extends FunkinSprite {
	public var name:String;
	public var player(default, set):Bool;
	
	// how many icons are in the grid
	// yes this allows for winning icons im so psych engine
	// all of them have to be in a row never more than one row
	var count:Int = 2;

	var iconOffsets:Array<Float> = [0, 0];

	public function new(name:String, ?player:Bool = false) {
		super(x, y);
		change(name);
		this.player = player;
	}

	public function change(value:String):String {
		if (!Assets.exists('images/icons/$value.png')) value = 'default';
		var graphic:FlxGraphic = Assets.image('images/icons/$value');
		var size:Float = Math.round(graphic.width / graphic.height);

		loadGraphic(graphic, true, Std.int(graphic.width / count), graphic.height);
		animation.add(value, [for (i in 0...frames.frames.length) i], 0, false);
		animation.play(value);

		iconOffsets = [(width - 150) / size, (height - 150) / size];
		updateHitbox();

		return this.name = value;
	}

	function set_player(value:Bool):Bool {
		flipX = value;
		return player = value;
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox():Void {
		super.updateHitbox();
		if (!autoAdjustOffset) return;
		offset.set(iconOffsets[0], iconOffsets[1]);
	}
}