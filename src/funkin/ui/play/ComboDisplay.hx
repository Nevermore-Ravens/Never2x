package funkin.ui.play;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import funkin.core.N2XStatistics.ClearType;

using flixel.util.FlxColorTransformUtil;

enum abstract ComboColorMode(Int) {
	var NONE;
	var PER_NOTE;
	var CLEAR_FLAG;
}

class ComboDisplay extends FlxTypedSpriteGroup<Number> {
	public static inline final default_precacheDigits:Int = 4;

	public var sheet(default, set):String = "images/ui/comboNums";
	public var minDigits:Int = 3;
	public var spacing:Float = 0;
	
	public var simple:Bool = false;
	public var yBump:Float = 5;

	public var colorMode:ComboColorMode = NONE;

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		for (i in 0...default_precacheDigits) add(new Number(sheet));
		scale.set(0.45, 0.45);
	}

	public function clearNums(?until:Int = 0) {
		while (length > until) {
			final num = members[0];
			remove(num, true);
			num.destroy();
		}
	}

	public function display(comboNum:Int) {
		if (Settings.data.comboAlpha <= 0) return;

		final comboStr:String = '$comboNum'.lpad('0', minDigits);
		// remove any excess numbers
		clearNums(comboStr.length);

		// then add any new ones
		for (_ in 0...comboStr.length - length) insert(0, new Number(sheet));

		for (i in 0...comboStr.length) {
			final num:Number = members[i];
			if (num == null) continue;

			final convertedNum:Int = comboStr.fastCodeAt(i) - '0'.code;//Std.parseInt(comboStr.charAt(i));

			final centerI = i - length * 0.5;
			if (num.animation.frameIndex != convertedNum) num.animation.frameIndex = convertedNum;
			num.scale.set(scale.x, scale.y);
			num.updateHitbox();
			num.setPosition(x + ((num.width + spacing) * centerI), y - yBump);
			num.visibility = Settings.data.comboAlpha;

			FlxTween.cancelTweensOf(num);
			
			num.moves = !simple;
			if (simple) {
				num.velocity.set();
				num.acceleration.y = 0;
				FlxTween.tween(num, {visibility: 0}, 0.35, {startDelay: 0.75});
				FlxTween.tween(num, {y: y}, 0.1, {
					onComplete: function(_) num.y = y,
					ease: FlxEase.cubeIn
				});
			} else {
				num.velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));
				num.acceleration.y = FlxG.random.int(250, 300);
				FlxTween.tween(num, {visibility: 0}, 0.2, {
					onComplete: function(_) num.visibility = 0,
					startDelay: Conductor.crotchet * 0.001
				});
			}
		}
	}

	public function colorizeCombo(judge:Judgement, clearType:ClearType) {
		var targetColor = switch (colorMode) {
			case PER_NOTE: judge.color;
			case CLEAR_FLAG: clearType.fullCombo ? clearType.color : 0xFFFFFFFF;
			default: 0xFFFFFFFF;
		};
		for (mem in members)
			mem.color = targetColor;
	}

	function set_sheet(to:String) {
		final texture = Assets.image(to);
		for (i in 0...members.length) {
			var num = members[i];
			var centerI = i - length * 0.5;
			var intendedX = x + ((num.width + spacing) * centerI);

			var anim = num.animation.frameIndex;
			num.loadGraphic(texture, true, Math.floor(texture.width * 0.2), Math.floor(texture.height * 0.5));
			num.animation.frameIndex = anim;
			num.updateHitbox();

			var newX = x + ((num.width + spacing) * centerI);
			num.x += newX - intendedX;
		}
		return sheet = to;
	}
}

class Number extends FunkinSprite {
	// using this instead of `alpha`
	// so you can set the `alpha` variable without fucking up anything
	public var visibility(default, set):Float = 1;
	function set_visibility(v:Float):Float {
		if (visibility == v) return v;

		visibility = FlxMath.bound(v, 0, 1);
		updateColorTransform();
		return visibility;
	}

	public function new(?sheet:String = "images/ui/comboNums") {
		super();

		final texture = Assets.image(sheet);
		loadGraphic(texture, true, Math.floor(texture.width * 0.2), Math.floor(texture.height * 0.5));
		visibility = 0;

		active = true;
		moves = true;
	}

	override function destroy() {
		FlxTween.cancelTweensOf(this);
		super.destroy();
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