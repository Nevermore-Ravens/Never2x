package funkin.objects;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import funkin.backend.Judgement;
import funkin.backend.Util;
import flixel.graphics.FlxGraphic;

using StringTools;

/**
 *
 * HitErrorBar like OSU!! 
 * @author BoloVEVO
 *
**/
class HitErrorBar extends FlxSpriteGroup
{
	var trianglePointer:FlxSprite;

	var timingBar:FlxSprite;

	var widthArray:Array<Float> = [];

	var currentMS:Float = 0;

	var lastMS:Float = 0;

	var middleLine:FlxSprite;

	var hitNotesGroup:FlxTypedSpriteGroup<NoteHitBar>;

	var missHitNote:NoteHitBar;

	var triangleRawPosition:Float;

	var alphaTime:Float = 0;

	public var curVisibleBars:Int = 0;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		this.x = x;
		this.y = y;
		this.alpha = 0.4;

		for (i in 0...Judgement.list.length * 2)
		{
			var id = i;
			if (id >= Judgement.list.length)
				id -= Judgement.list.length;
            
			widthArray[i] = i < Judgement.list.length ? Judgement.list[Judgement.list.length-id-1].timing
				- (Judgement.list[Judgement.list.length-id-2] != null ? Judgement.list[Judgement.list.length-id-2].timing : 0) : Judgement.list[id].timing
					- (Judgement.list[id-1] != null ? Judgement.list[id-1].timing: 0);
		}

		var totalWidth = 0.0;
		for (i in widthArray)
			totalWidth += i;

		var judgeLine:BitmapData = new BitmapData(5, Std.int(totalWidth), true);

		var daOffset = 0.0;

		for (i in 0...Judgement.list.length * 2) 
		{
			var id = i;
			if (id >= Judgement.list.length)
				id -= Judgement.list.length;

			final shitWidth = widthArray[i];
            final curColor:FlxColor = i < Judgement.list.length ? Judgement.list[Judgement.list.length-id-1].color : Judgement.list[id].color;

			judgeLine.fillRect(new openfl.geom.Rectangle(0, daOffset, 5, shitWidth),
				curColor);
			daOffset += widthArray[i];
		}

		timingBar = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(judgeLine, false, "judgeLine"));

		timingBar.setGraphicSize(5, 300); // Set to a determined scale to don't have a large timing bar because of really high timings.

		timingBar.updateHitbox();

		trianglePointer = new FlxSprite(0, (timingBar.y + timingBar.height / 2) - 5).makeGraphic(10, 10, FlxColor.TRANSPARENT);

		FlxSpriteUtil.drawTriangle(trianglePointer, 0, 0, 10, FlxColor.WHITE, {thickness: 0, color: FlxColor.WHITE}, {smoothing: true});

		trianglePointer.scale.set(1, 0.65);
		trianglePointer.updateHitbox();
		trianglePointer.moves = false;
        trianglePointer.visible = true;
		trianglePointer.antialiasing = Settings.data.antialiasing;
		updatePointerFlip();

		middleLine = new FlxSprite(-10.5, (timingBar.y + timingBar.height / 2) - 1.5).makeGraphic(25, 3, FlxColor.WHITE);

		hitNotesGroup = new FlxTypedSpriteGroup<NoteHitBar>(0, 0, 0);

		for (i in 0...hitNotesGroup.maxSize + 1)
		{
			final dummyBar = new NoteHitBar(this, (timingBar.x + timingBar.width / 2) - 1.5, -10.5);
			dummyBar.makeGraphic(18, 3, FlxColor.WHITE);
			dummyBar.moves = false;
			hitNotesGroup.insert(0, dummyBar);
			dummyBar.kill();
		}

		missHitNote = new NoteHitBar(this, timingBar.x + timingBar.width - 1.5, -10.5);
		missHitNote.makeGraphic(18, 3, FlxColor.WHITE);
		missHitNote.visible = false;
		missHitNote.moves = false;
		missHitNote.kill();

		curVisibleBars = 0;

		add(timingBar);

		add(middleLine);
		add(trianglePointer);
		add(missHitNote);

		add(hitNotesGroup);
	}

	public function updatePointerFlip()
	{
		if (Settings.data.gameplayModifiers['playingSide'] == 'Opponent')
		{
			trianglePointer.angle = 90;
			trianglePointer.x = -12;
		}
		else
		{
			trianglePointer.angle = -90;
			trianglePointer.x = 12.5;
		}

		trianglePointer.alpha = 0.7;
	}

	var trianglePos:Float = 0;

	override function update(elapsed:Float)
	{
		if (trianglePointer.visible)
		{
			var rawPos = FlxMath.remapToRange((timingBar.y + timingBar.height * 0.5)
				+ currentMS, (timingBar.y + timingBar.height * 0.5),
				(timingBar.y + timingBar.height * 0.5)
				+ Judgement.max.timing, (timingBar.y + timingBar.height * 0.5), timingBar.y
				+ timingBar.height)
				- 5;

			trianglePos = rawPos;

			trianglePointer.y = Util.expDecay(trianglePointer.y, rawPos, 7.5);
		}

		if (timingBar.visible)
			if (curVisibleBars <= 0)
				if (timingBar.alpha > 0.4)
					timingBar.alpha -= 0.1 * elapsed;
	}

	public function registerHit(noteMS:Float)
	{
		lastMS = currentMS;
		currentMS = noteMS;

		alphaTime = 0;
		timingBar.alpha = 0.7;
		trianglePointer.alpha = 0.7;

		var barPos = FlxMath.remapToRange((timingBar.y + timingBar.height * 0.5)
			+ currentMS, (timingBar.y + timingBar.height * 0.5),
			(timingBar.y + timingBar.height * 0.5)
			+ Judgement.max.timing, (timingBar.y + timingBar.height * 0.5), timingBar.y
			+ timingBar.height)
			- 1.5;

		final hitBar:NoteHitBar = hitNotesGroup.recycle(NoteHitBar, generateNewHitBar);
        hitBar.loadGraphic(hitNotesGroup.members[0].graphic);
		hitBar.camera = camera;
		hitBar.setPosition(x - 7, barPos);
	}

    private function generateNewHitBar()
    {
        return new NoteHitBar(this, -10.5, (timingBar.y + timingBar.height / 2) - 1.5);
    }

	public function registerMiss()
	{
		alphaTime = 0;
		timingBar.alpha = 0.7;
		trianglePointer.alpha = 0.7;

        lastMS = currentMS;
		currentMS = Judgement.max.timing;

		triangleRawPosition = timingBar.y + timingBar.height - 1.5;
		missHitNote.revive();
        missHitNote.visible = true;
		missHitNote.setPosition(x - 7, timingBar.y + timingBar.height - 1.5);
	}

	override function destroy()
	{
		widthArray.splice(0, widthArray.length);

		super.destroy();
	}
}

class NoteHitBar extends FlxSprite
{
	public var existTime:Float = 0;

	var errorBar:HitErrorBar;

	public function new(errorBar:HitErrorBar, x:Float, y:Float)
	{
		super(x, y);
		this.errorBar = errorBar;
	}

	override function draw()
	{
		super.draw();

		existTime += FlxG.elapsed * 1000;
		if (existTime > 1000)
			alpha -= 0.1 * FlxG.elapsed;

		if (alpha <= 0.001)
			kill();
	}

	override function revive()
	{
		visible = true;
		alpha = 0.7;
		if (!alive)
			errorBar.curVisibleBars++;
		super.revive();
	}

	override function kill()
	{
		visible = false;
		existTime = 0;
		super.kill();

		errorBar.curVisibleBars--;
	}

	override function destroy()
	{
		super.destroy();
		errorBar = null;
	}
}
