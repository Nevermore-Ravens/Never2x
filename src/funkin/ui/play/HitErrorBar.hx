package funkin.ui.play;

import nevermore.core.Judgement;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flixel.util.FlxSpriteUtil;

// cheers to bolovevo for this class
// his was a major "inspiration" for like
// Basically Every Equation Here
//
// i say inspiration with quotation marks like i didn't just copy paste
class HitErrorBar extends FlxSpriteGroup {
	// the actual hit error bar itself
	// with colours and whatnot
	var line:FlxSprite;

	// the pointer triangle below the bar
	var pointer:FlxSprite;

	var hitRegistery:FlxTypedSpriteGroup<NoteHitBar>;


	public function new(?x:Float = 0.0, ?y:Float = 0.0, ?list:Array<Judgement>) {
		super();

		list ??= Judgement.current;

		// grab the highest hit window
		var highestWindow:Float = list[list.length - 1].window;
		// multiply by 2 since this goes both ways
		var bitmapLine:BitmapData = new BitmapData(Std.int(highestWindow * 2), 5, true);

		var rect = new openfl.geom.Rectangle(0, 0, 1, bitmapLine.height);
		var posOffset:Float = 0.0;
		for (i in 0 ... list.length) {
			var width:Float = list[i].window;
			var colour:Int = list[i].color;
			rect.width = width;

			rect.x = highestWindow - posOffset - width; // top-left positioning, offset by width to "right-align" it
			bitmapLine.fillRect(rect, colour);
			rect.x = highestWindow + posOffset;
			bitmapLine.fillRect(rect, colour);

			posOffset = width;
		}

		line = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(bitmapLine, false, 'judgeLine'));

		/*line.setGraphicSize(, 5);
		line.updateHitbox();*/

		add(line);
		line.alpha = 0.4;

		pointer = new FlxSprite((line.x + line.width / 2) - 5, 12.5).makeGraphic(10, 10, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawTriangle(pointer, 0, 0, 10, FlxColor.WHITE, {thickness: 0, color: FlxColor.WHITE}, {smoothing: true});
		pointer.scale.set(1, 0.65);
		pointer.updateHitbox();
        pointer.visible = true;

		add(pointer);

		add(hitRegistery = new FlxTypedSpriteGroup<NoteHitBar>());
	}

	var curDeviation:Float = 0.0;
	override function update(elapsed:Float) {
		if (!pointer.visible) return;

		var lineLength:Float = line.x + line.width;
		var lineCenter:Float = line.x + (line.width / 2);

		var rawPos = FlxMath.remapToRange(curDeviation, -Judgement.max.window, Judgement.max.window, line.x, line.x + line.width) - pointer.width;

		pointer.x = Util.expDecay(pointer.x, rawPos, 7.5);
	}

	public function hit(deviation:Float) {
		curDeviation = deviation;

		final hitBar:NoteHitBar = hitRegistery.recycle(NoteHitBar);
		hitBar.setup();

		var lineLength:Float = line.x + line.width;
		var lineCenter:Float = line.x + (line.width / 2);

		var barPos:Float = FlxMath.remapToRange(deviation, -Judgement.max.window, Judgement.max.window, line.x, line.x + line.width - hitBar.width);
		hitBar.camera = camera;
		hitBar.setPosition(barPos, this.y - 7);
		hitBar.alpha = 0.7;
	}
}

class NoteHitBar extends FlxSprite {
	// the amount of time bars take to start fading in seconds
	public static var fadeDelay:Float = 0.5;

	public var existTime:Float = 0.0;

	public function setup() {
		if (graphic != null) return;

		makeGraphic(3, 18, FlxColor.WHITE);
	}

	override function draw() {
		super.draw();

		existTime += FlxG.elapsed;
		if (existTime > fadeDelay)
			alpha -= 0.25 * FlxG.elapsed;

		if (alpha <= 0.0) kill();
	}

	override function revive() {
		alive = true;
		exists = true;
	}

	override function kill() {
		alive = false;
		exists = false;

		existTime = 0.0;
	}
}