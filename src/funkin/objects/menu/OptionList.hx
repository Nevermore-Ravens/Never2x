package funkin.objects.menu;

import flixel.math.FlxRect;
import funkin.states.OptionsState.Option;

class OptionList extends TextList {
	var list:Array<Option>;
    var selPercentages:Array<Float> = [];
	var componGrp:FlxTypedGroup<FlxSprite>;
	var invertCompons:FlxTypedGroup<FlxSprite>;
	public var components:Array<OptionComponent<FlxSprite>> = [];

	public function new(x:Float, y:Float, width:Float, height:Float) {
		super(x, y, width, height, []);
		componGrp = new FlxTypedGroup();
		invertCompons = new FlxTypedGroup();
	}

    override function mouseControl() {
		for (i in 0...texts.length) {
            var height = (texts.members[current].height + (hasSubTexts ? (subTexts.members[current].height + 5) * selPercentages[i] : 0));
			var top = texts.members[i].y - 5;

			if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + height && canSelect(i)) {
				retarget((mouseMoved || FlxG.mouse.justPressed) ? i : current);

				components[i].hovering(list[i]);
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
		while (invertCompons.length > 0) {
			final compon = invertCompons.members[0];
			invertCompons.remove(compon, true);
			compon.destroy();
		}
		components.resize(list.length);

		for (i => opt in list) {
			var compon:OptionComponent<FlxSprite> = cast switch (opt.type) {
				case BoolOption:
					subTexts.members[i].fieldWidth -= 65;
					new Checkbox(opt);
				case IntOption(min, max, inc, wrap, true):
					subTexts.members[i].fieldWidth -= 300;
					new Slider(opt, i == current);
				case FloatOption(min, max, inc, wrap, true): // case ors were being a BITCH
					subTexts.members[i].fieldWidth -= 300;
					new Slider(opt, i == current);
				default:
					subTexts.members[i].fieldWidth -= 150;
					new Textbox(opt, i == current);
			}
			compon.position(texts.members[i], subTexts.members[i], selPercentages[i]);
			compon.clip(y, y + height);

			(compon.canInvert ? invertCompons : componGrp).add(compon.obj);
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
		invertCompons.draw();
		hover.draw();
		hover.blend = NORMAL;

		componGrp.draw();
	}
}

interface OptionComponent<T:FlxSprite> {
	public var obj:T;
	public var canInvert:Bool;

	public function hovering(opt:Option):Void;
	public function position(txt:FlxText, sub:FlxText, selPercent:Float):Void;
	public function clip(top:Float, bottom:Float):Void;
	public function change(opt:Option):Void;
	public function selectionChanged(opt:Option, selected:Bool):Void;
}

class Checkbox extends FunkinSprite implements OptionComponent<Checkbox> {
	public var obj:Checkbox;
	public var canInvert:Bool;

	public function hovering(opt:Option) {}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;

		setPosition(txt.x + txt.width - width, y + (height - this.height) * 0.5);
		scale.x = scale.y = 0.5 + 0.5 * selPercent;
	}
	public function clip(top:Float, bottom:Float) {
		//var y =  Math.max(top - y, 0);
		//clipRect = clipRect.set(0, y, frameWidth, frameHeight - y - Math.max((y + height) - bottom, 0));
	}
	public function change(opt:Option):Void {
		var curAnim = animation.name;
		var lastFrame = (curAnim != null && curAnim.startsWith("to")) ? animation.curAnim.numFrames - 1 - animation.curAnim.curFrame : -1;
		playAnim("to" + (opt.value == true));
		if (lastFrame >= 0 && animation.curAnim != null)
			animation.curAnim.curFrame = lastFrame;
	}
	public function selectionChanged(opt:Option, selected:Bool) {}

	public function new(opt:Option) {
		super();
		obj = this;
		canInvert = false;
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
		clipRect = FlxRect.get(0, 0, frameWidth, frameHeight);
	}
}

class Textbox extends FlxText implements OptionComponent<Textbox> {
	public var obj:Textbox;
	public var canInvert:Bool;

	public function hovering(opt:Option) {}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;

		regenGraphic();
		offset.x = origin.x = graphic.width;
		scale.x = scale.y = 0.65 + 0.35 * selPercent;
		setPosition(txt.x + txt.width, y + (height - this.height) * 0.5);
	}
	public function clip(top:Float, bottom:Float) {
		//Util.clipByCoords(this, null, null, top, bottom);
	}
	public function change(opt:Option):Void {
		text = opt.formatText(true);
		if (opt.textboxArrows)
			text = "< " + text + " >";
	}
	public function selectionChanged(opt:Option, selected:Bool) {
		text = opt.formatText(selected);
		if (selected && opt.textboxArrows)
			text = "< " + text + " >";
	}

	public function new(opt:Option, selected:Bool) {
		super(0, 0, 0, opt.formatText(selected));
		if (selected && opt.textboxArrows)
			text = "< " + text + " >";

		obj = this;
		canInvert = true;
		setFormat(Paths.font("cafeSquare.ttf"), 40, 0xFFFFFFFF, RIGHT);
	}
}

class Slider extends FunkinSprite implements OptionComponent<Slider> {
	static inline final BAR_PADDING:Float = 4;

	public var obj:Slider;
	public var canInvert:Bool;
	var fillPercent:Float;
	var fill:FunkinSprite;
	var label:FlxText;

	var min:Float;
	var max:Float;

	public function hovering(opt:Option) {}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;
		final scale = 0.5 + 0.5 * selPercent;

		this.scale.set(this.width * scale, this.height * scale);
		this.setPosition(txt.x + txt.width - this.scale.x, y + (height - this.scale.y) * 0.5);

		fill.scale.set(
			(this.width - BAR_PADDING * 2) * scale * fillPercent,
			(this.height - BAR_PADDING * 2) * scale
		);
		fill.setPosition(this.x + BAR_PADDING * scale, this.y + BAR_PADDING * scale);

		@:privateAccess label.regenGraphic();
		label.offset.x = label.origin.x = label.graphic.width;
		label.scale.set(scale, scale);
		label.setPosition(x, this.y + (this.scale.y - label.height) * 0.5);
	}
	public function clip(top:Float, bottom:Float) {
		//Util.clipByCoords(this, null, null, top, bottom);
	}
	public function change(opt:Option):Void {
		fillPercent = (opt.value - min) / (max - min);
		fill.scale.x = (width - BAR_PADDING * 2) * label.scale.x * fillPercent;
		label.text = opt.formatText(true);
	}
	public function selectionChanged(opt:Option, selected:Bool) {
		label.text = opt.formatText(selected);
	}

	public function new(opt:Option, selected:Bool) {
		super();
		obj = this;
		canInvert = true;

		makeGraphic(1, 1);
		scale.set(200, 40);
		updateHitbox();
		origin.set();
		offset.set();

		final params = opt.type.getParameters();
		min = params[0];
		max = params[1];
		fillPercent = (opt.value - min) / (max - min);

		fill = new FunkinSprite();
		fill.makeGraphic(1, 1);
		fill.scale.set((width - BAR_PADDING * 2) * fillPercent, height - BAR_PADDING * 2);
		fill.color = 0xFF000000;
		fill.updateHitbox();
		fill.origin.set();
		fill.offset.set();

		label = new FlxText(0, 0, 0, opt.formatText(selected));
		label.setFormat(Paths.font("cafeSquare.ttf"), 32, 0xFFFFFFFF, RIGHT);
	}

	override function draw() {
		super.draw();
		fill.draw();
		label.draw();
	}
}