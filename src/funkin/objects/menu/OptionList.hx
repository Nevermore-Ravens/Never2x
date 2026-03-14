package funkin.objects.menu;

import flixel.FlxSprite.IFlxSprite;
import funkin.states.OptionsState.Option;

class OptionList extends TextList {
	var list:Array<Option>;
    var selPercentages:Array<Float> = [];
	var componGrp:FlxTypedGroup<FlxSprite>;
	public var components:Array<OptionComponent<FlxSprite>> = [];

	public function new(x:Float, y:Float, width:Float, height:Float) {
		super(x, y, width, height, []);
		componGrp = new FlxTypedGroup();
	}

    override function mouseControl() {
		for (i in 0...texts.length) {
            var height = (texts.members[current].height + (hasSubTexts ? (subTexts.members[current].height + 5) * selPercentages[i] : 0));
			var top = texts.members[i].y - 5;

			if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + height && canSelect(i)) {
				retarget((mouseMoved || FlxG.mouse.justPressed) ? i : current);

				if (FlxG.mouse.justPressed && onClick != null)
					onClick(i);
				break;
			}
		}
	}

    override function position(elapsed:Float) {
		// shhhhh
		componGrp.update(elapsed);

		curScroll = FlxMath.lerp(curScroll, scrollInc * current, elapsed * 15);
        var y = y + 15 - curScroll;
		for (i in 0...texts.length) {
            final txt = texts.members[i];
			txt.setPosition(x + 15, y);
			txt.alpha = alpha;
            Util.clipByCoords(txt, null, null, y, y + height);
            
            selPercentages[i] = FlxMath.lerp(selPercentages[i], (i == current ? 1 : 0), elapsed * 15);
			if (hasSubTexts) {
                final sub = subTexts.members[i];
				sub.setPosition(txt.x, txt.y + (txt.height - 5) * selPercentages[i]);
				sub.alpha = alpha * selPercentages[i];
                Util.clipByCoords(sub, null, null, y, y + height);
                
                y += (sub.height + 5) * selPercentages[i];
				components[i].position(txt, sub, selPercentages[i]);
				components[i].clip(y, y + height);
			}

            y += txt.height;
		}
        scrollInc = Math.max((y + curScroll - this.y - 15 + 60) - height, 0) / texts.length;
        var targetHeight = (texts.members[current].height + (hasSubTexts ? (subTexts.members[current].height - 5) * selPercentages[current] : 0)) + 10;
        hover.y = FlxMath.lerp(hover.y, texts.members[current].y - 5, elapsed * 15);
        hover.scale.y = FlxMath.lerp(hover.scale.y, targetHeight, elapsed * 15);
        hover.alpha = alpha;
	}

    override function regenerate(txts:Array<String>, ?subs:Array<String>) {
		hasSubTexts = subs != null;

		while (texts.length > 0) {
			final txt = texts.members[0];
			texts.remove(txt, true);
			txt.destroy();
		}
		while (subTexts.length > 0) {
			final sub = subTexts.members[0];
			subTexts.remove(sub, true);
			sub.destroy();
		}
        selPercentages.resize(txts.length);

		current = 0;
		var y = y + 15;
		for (i in 0...txts.length) {
            selPercentages[i] = i == current ? 1 : 0;

			var txt = new FlxText(x + 15, y, width - 30, txts[i]);
			txt.setFormat(Paths.font("cafeSquare.ttf"), 24, 0xFFFFFFFF, LEFT);
			txt.antialiasing = Settings.data.antialiasing;
			texts.add(txt);

			if (hasSubTexts) {
				var sub = new FlxText(txt.x, txt.y + (txt.height - 5) * selPercentages[i], width - 30, subs[i]);
				sub.setFormat(Paths.font("cafeSquare.ttf"), 16, 0xFFFFFFFF, LEFT);
				sub.antialiasing = Settings.data.antialiasing;
				subTexts.add(sub);
                sub.alpha = selPercentages[i];
                y += (sub.height + 5) * selPercentages[i];
			}

			y += txt.height;
		}
		scrollInc = Math.max((y - this.y - 15 + 60) - height, 0) / txts.length;
	}
	public function setOptions(list:Array<Option>) {
		var txts = [for (opt in list) (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name))];
		var subs = [for (i => opt in list) getDesc(opt)];
		regenerate(txts, subs);
		this.list = list;

		while (componGrp.length > 0) {
			final compon = componGrp.members[0];
			componGrp.remove(compon, true);
			compon.destroy();
		}
		components.resize(list.length);

		for (i => opt in list) {
			var compon:OptionComponent<FlxSprite> = cast switch (opt.type) {
				default:
					new Checkbox(opt);
			}
			compon.position(texts.members[i], subTexts.members[i], selPercentages[i]);
			compon.clip(y, y + height);

			componGrp.add(compon.obj);
			components[i] = compon;
		}
	}

	public static function getDesc(opt:Option) {
		return (opt.desc.startsWith("<NO-LANG>") ? opt.desc.substring(9, opt.desc.length) : _formatT(opt.desc, [_t("accept").toUpperCase()]));
	}

	override function draw() {
		superDraw();
		// i'm sorry -Nebula
		hover.draw();
		hover.blend = INVERT;
		hover.draw();
		texts.draw();
		subTexts.draw();
		hover.draw();
		hover.blend = NORMAL;

		componGrp.draw();
	}
}

interface OptionComponent<T:FlxSprite> {
	public var obj:T;

	public function tryMouse():Void;
	public function position(txt:FlxText, sub:FlxText, selPercent:Float):Void;
	public function clip(top:Float, bottom:Float):Void;
	public function change(opt:Option):Void;
}

class Checkbox extends FunkinSprite implements OptionComponent<FunkinSprite> {
	public var obj:FunkinSprite;

	public function tryMouse() {}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;

		setPosition(txt.x + txt.width - width, y + (height - this.height) * 0.5);
		scale.x = scale.y = 0.65 + 0.35 * selPercent;
	}
	public function clip(top:Float, bottom:Float) {}
	public function change(opt:Option):Void {
		var curAnim = animation.name;
		var lastFrame = (curAnim != null && curAnim.startsWith("to")) ? animation.curAnim.numFrames - 1 - animation.curAnim.curFrame : -1;
		playAnim("to" + (opt.value == true));
		if (lastFrame >= 0 && animation.curAnim != null)
			animation.curAnim.curFrame = lastFrame;
	}

	public function new(opt:Option) {
		super();
		obj = this;
		frames = Paths.sparrowAtlas("menus/options/optionsbuttongay");
		animation.addByPrefix("true", "ON", 12, false);
		animation.addByPrefix("totrue", "TURN", 12, false);
		animation.addByPrefix("false", "OFF", 12, false);
		animation.addByPrefix("tofalse", "RTURN", 12, false);
		playAnim(Std.string(opt.value == true));

		animation.finishCallback = function(name) {
			if (name.startsWith("to"))
				playAnim(name.substring(2));
		};
	}
}