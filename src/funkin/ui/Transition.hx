package funkin.ui;

import flixel.util.FlxGradient;

/**
this is literally just psych's transition class i am SO sorry
now slightly edited because this actually kinda sucked ass
@author Shadow_Mario_
*/
class Transition extends FlxSubState {
	public static dynamic function finishCallback() {}
	var isTransIn:Bool = false;

	var gradient:FlxSprite;
	var black:FlxSprite;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create() {
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var zoom:Float = Math.max(camera.zoom, 0.001);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);

		var colours:Array<Int> = [FlxColor.BLACK, 0x0];
		if (isTransIn) colours.reverse();

		add(gradient = FlxGradient.createGradientFlxSprite(1, height, colours));
		gradient.scale.x = width;
		gradient.updateHitbox();
		gradient.scrollFactor.set();
		gradient.screenCenter(X);

		add(black = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK));
		black.scale.set(width, height + 400);
		black.updateHitbox();
		black.scrollFactor.set();
		black.screenCenter(X);

		if (isTransIn) {
			gradient.y = black.y - black.height;
			black.y = gradient.y + gradient.height;
		} else {
			gradient.y = -gradient.height;
			black.y = gradient.y - black.height;
		}
	}

	override function update(elapsed:Float) {
		var zoom:Float = Math.max(camera.zoom, 0.001);
		var height:Float = FlxG.height * zoom;
		var targetPos:Float = gradient.height + 50 * zoom;

		if (duration <= 0) gradient.y = targetPos;
		else {
			gradient.y += (height + targetPos) * elapsed / duration;
		}

		if (isTransIn) black.y = gradient.y + gradient.height;
		else black.y = gradient.y - black.height;

		if (gradient.y >= targetPos) close();
	}

	// Don't delete this
	override function close():Void {
		super.close();

		finishCallback();
		finishCallback = function() {}
	}
}
