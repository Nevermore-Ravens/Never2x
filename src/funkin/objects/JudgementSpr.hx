package funkin.objects;

import funkin.backend.Judgement;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using flixel.util.FlxColorTransformUtil;

class JudgementSpr extends FunkinSprite {
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
		final texture = Paths.image('ui/judgements');
		loadGraphic(texture, true, texture.width, Math.floor(texture.height / Judgement.list.length));
		
		visibility = 0;

		active = true;
		scale.set(0.65, 0.65);
		updateHitbox();
	}
	
	public function display(timing:Float) {
		if (Settings.data.judgementAlpha <= 0) return;

		Main.tweenManager.cancelTweensOf(this);
		animation.frameIndex = Judgement.getIDFromTiming(timing);
		if (animation.frameIndex == 0 && Settings.data.hideHighest) {
			visibility = 0;
			return;
		}
		
		centerOffsets();
		visibility = Settings.data.judgementAlpha;
		Main.tweenManager.tween(this, {visibility: 0}, 0.35, {startDelay: 0.75});
		
		moves = !simple;
		setPosition(ogX, ogY);
		if (simple) {
			velocity.set();
			acceleration.y = 0;
			scale.scale(1.125);
			Main.tweenManager.cancelTweensOf(this.scale);
			Main.tweenManager.tween(this.scale, {x: scale.x / 1.125, y: scale.y / 1.125}, 0.2, {ease: FlxEase.cubeIn});
		} else {
			velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));
			acceleration.y = 550;
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