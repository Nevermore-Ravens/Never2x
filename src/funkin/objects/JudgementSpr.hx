package funkin.objects;

import funkin.backend.Judgement;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using flixel.util.FlxColorTransformUtil;

class JudgementSpr extends FunkinSprite {
	// using this instead of `alpha`
	// so you can set the `alpha` variable without fucking up anything
	var visibility(default, set):Float = 1;
	function set_visibility(v:Float):Float {
		if (visibility == v) return v;

		visibility = FlxMath.bound(v, 0, 1);
		updateColorTransform();
		return visibility;
	}

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		loadGraphic(Paths.image('ui/judgements'), true, 500, 250);
		
		visibility = 0;

		moves = true;
		active = true;
		scale.set(0.45, 0.45);
		updateHitbox();
	}
	
	public function display(timing:Float) {
		if (Settings.data.judgementAlpha <= 0) return;

		animation.frameIndex = Judgement.getIDFromTiming(timing);
		centerOffsets();
		visibility = Settings.data.judgementAlpha;
		scale.set(0.45, 0.45);

		FlxTween.cancelTweensOf(this);
		FlxTween.cancelTweensOf(this.scale);

		FlxTween.tween(this, {visibility: 0}, 0.35, {startDelay: 0.75});
		FlxTween.tween(this.scale, {x: 0.4, y: 0.4}, 0.2, {ease: FlxEase.cubeIn});
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
}