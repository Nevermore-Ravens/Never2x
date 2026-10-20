package funkin.ui.play;

import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using flixel.util.FlxColorTransformUtil;

class JudgeDisplay extends FunkinSprite {
	public var simple:Bool = false;
	
	// using this instead of `alpha`
	// so you can set the `alpha` variable without fucking up anything
	var visibility(default, set):Float = 1;
	function set_visibility(v:Float):Float {
		if (visibility == v) return v;

		visibility = FlxMath.bound(v, 0, 1);
		updateColorTransform();
		return visibility;
	}

	var ogX:Float = 0;
	var ogY:Float = 0;
	var inMotion:Bool = false;
	public function new(?x:Float, ?y:Float) {
		super(x, y);
		ogX = x;
		ogY = y;
		var texture = Assets.image('images/ui/judgements.png');

		var textureHeight:Int = Math.floor(texture.height / (Judgement.current.length + 1));
		loadGraphic(texture, true, texture.width, textureHeight);
		
		visibility = 0;

		active = true;
		scale.set(0.65, 0.65);
		updateHitbox();
	}
	
	public function display(?judgeID:Int) {
		FlxTween.cancelTweensOf(this);
		animation.frameIndex = judgeID ?? Judgement.current.length;
		
		visibility = 1;
		centerOffsets();
		
		moves = !simple;
		setPosition(ogX, ogY);
	
		if (simple) { // camellia/notitg-like judgements
			velocity.set();
			acceleration.y = 0;

			FlxTween.cancelTweensOf(this.scale);
			scale.set(0.7, 0.7);

			FlxTween.tween(this, {visibility: 0}, 0.35, {startDelay: 0.75});
			FlxTween.tween(this.scale, {x: 0.65, y: 0.65}, 0.2, {ease: FlxEase.cubeIn});
		} else { // fnf-like judgements
			velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));
			acceleration.y = 550;
			FlxTween.tween(this, {visibility: 0}, 0.2, {startDelay: Conductor.crotchet * 0.001});
		}
	}

	override function update(elapsed:Float) {
		if (moves) {
			inMotion = true;
			updateMotion(elapsed);
			inMotion = false;
		}

		updateAnimation(elapsed);
	}

	override function draw():Void {
		if (visibility <= 0) return;

		super.draw();
	}

	override function updateColorTransform():Void {
		if (colorTransform == null) return;

		useColorTransform = alpha != 1 || visibility != 1 || color != 0xffffff;
		if (useColorTransform) this.colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, visibility * alpha);
		else this.colorTransform.setMultipliers(1, 1, 1, 1);

		dirty = true;
	}

	override function set_x(to:Float) {
		if (!inMotion)
			ogX = to;
		return x = to; 
	}
	override function set_y(to:Float) {
		if (!inMotion)
			ogY = to;
		return y = to; 
	}
}