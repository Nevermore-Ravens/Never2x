package funkin.objects.menu;

import flixel.math.FlxRect;
import funkin.states.OptionsState.Option;

class OptionList extends TextList {
	// 0 - None, 1 - Left, 2 - Right, 3 - Mouse Left, 4 - Mouse Right
	public var curHolding:Int = 0;
	public var holdWait:Float = 0.5;
	public var dragging:Bool = false;

	var hoverHeight:Float = 30;
    var selPercentages:Array<Float> = [];
	public var list:Array<Option>;
	public var components:Array<OptionComponent<FlxSprite>> = [];

	public var onOptMove:(current:Int, left:Bool)->Void;
	public var onOptEnter:(current:Int)->Void;

	public function new(x:Float, y:Float, width:Float, height:Float) {
		super(x, y, width, height, []);
		canSelect = (target) -> list[target].type != Unselectable;
	}

	override function retarget(target:Int) {
		if (current == target) return;

		var last:Int = current;
		current = target;

		components[last].selectionChanged(list[last], false);
		components[current].selectionChanged(list[current], true);
		FlxG.sound.play(Assets.audio("sfx/scroll"));

		if (onSelect != null)
			onSelect(current, last);
	}

	override function keyControl(elapsed:Float) {
		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			final firstNew = FlxMath.wrap(current + (downJustPressed ? 1 : -1), 0, texts.length - 1);
			var target = firstNew;
			while (!canSelect(target)) {
				target = FlxMath.wrap(target + (downJustPressed ? 1 : -1), 0, texts.length - 1);
				if (target == firstNew)
					break; // safety
			}
			dragging = false;
			curHolding = 0;
			retarget(target);
		}

		final curOption = list[current];
		final leftJustPressed:Bool = Controls.justPressed('ui_left');
		if ((leftJustPressed || Controls.justPressed('ui_right')) && curOption.hasMove) {
			dragging = false;
			curHolding = leftJustPressed ? 1 : 2;
			holdWait = 0.5;

			if (curOption.hasSound)
				FlxG.sound.play(Assets.audio("sfx/" + curOption.sound));
			curOption.change(leftJustPressed);
			components[current].change(curOption);

			if (onOptMove != null)
				onOptMove(current, leftJustPressed);
		}
		if (Controls.justPressed('accept')) {
			if (curOption.hasEnter) {
				if (curOption.hasSound)
					FlxG.sound.play(Assets.audio("sfx/" + curOption.sound));

				dragging = false;
				curHolding = 0;
				curOption.enter();
				components[current].change(curOption);

				if (onOptEnter != null)
					onOptEnter(current);
			}

			if (onAccept != null)
				onAccept(current);
		}
		
		curHolding = switch (curHolding) {
			case 1: Controls.pressed("ui_left") ? 1 : 0;
			case 2: Controls.pressed("ui_right") ? 2 : 0;
			case 3 | 4: FlxG.mouse.pressed ? curHolding : 0;
			default: 0;
		};
		if (curHolding != 0) {
			holdWait -= elapsed;
			if (holdWait <= 0) {
				holdWait = 0.035; // make the changing more consistent
				curOption.change(curHolding % 2 == 1);
				components[current].change(curOption);

				if (onOptMove != null)
					onOptMove(current, curHolding % 2 == 1);
			}
		}
	}

    override function mouseControl() {
		if (dragging) {
			components[current].hovering(current, list[current], this, mousePoint);
			return;
		}

		for (i in 0...texts.length) {
            var height = (texts.members[current].height + (hasSubTexts ? (subTexts.members[current].height + 5) * selPercentages[i] : 0));
			var top = texts.members[i].y - 5;

			if (mousePoint.y >= top && mousePoint.y <= top + height && canSelect(i)) {
				retarget((mouseMoved || FlxG.mouse.justPressed) ? i : current);

				components[i].hovering(i ,list[i], this, mousePoint);
				if (FlxG.mouse.justPressed && onClick != null)
					onClick(i);
				break;
			}
		}
	}

    override function position(elapsed:Float) {
		// shhhhh
		for (compon in components) {
			if (compon != null && compon.obj.active)
				compon.update(elapsed);
		}

		curScroll = FlxMath.lerp(curScroll, scrollInc * current, elapsed * 15);
        var y = y + 15 - curScroll;
		for (i in 0...texts.length) {
            final txt = texts.members[i];
			txt.setPosition(x + 15, y);
			txt.alpha = alpha;
            Util.clipByCoords(txt, null, null, this.y, this.y + scale.y);
            
            selPercentages[i] = FlxMath.lerp(selPercentages[i], (i == current ? 1 : 0), elapsed * 15);
			txt.color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercentages[i]);
			if (hasSubTexts) {
                final sub = subTexts.members[i];
				sub.setPosition(txt.x, txt.y + (txt.height - 5) * selPercentages[i]);
				sub.alpha = alpha * selPercentages[i];
				sub.color = txt.color;
                Util.clipByCoords(sub, null, null, this.y, this.y + scale.y);
                
                y += (sub.height + 5) * selPercentages[i];
				components[i].position(txt, sub, selPercentages[i]);
				components[i].clip(this.y, this.y + scale.y);
			}

            y += txt.height;
		}
        scrollInc = Math.max((y + curScroll - this.y - 15 + 60) - height, 0) / texts.length;
        var targetHeight = (texts.members[current].height + (hasSubTexts ? (subTexts.members[current].height - 5) * selPercentages[current] : 0)) + 10;
		hoverY = FlxMath.lerp(hoverY, texts.members[current].y - 5, elapsed * 15);
        hover.setPosition(x, hoverY);
        hoverHeight = FlxMath.lerp(hoverHeight, targetHeight, elapsed * 15);
		hover.alpha = FlxMath.lerp(hover.alpha, displayHover ? alpha : 0, elapsed * 15);

		hover.scale.y = hoverHeight;
		hover.scale.y -= Math.max((hover.y + hoverHeight) - (this.y + scale.y), 0);
		var topClip = Math.max(this.y - hover.y, 0);
		hover.y += topClip;
		hover.scale.y -= topClip;
		hover.scale.y = Math.max(hover.scale.y, 0);
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
			txt.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 24, 0xFFFFFFFF, LEFT);
			txt.antialiasing = Settings.data.antialiasing;
			texts.add(txt);

			if (hasSubTexts) {
				var sub = new FlxText(txt.x, txt.y + (txt.height - 5) * selPercentages[i], width - 30, subs[i]);
				sub.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 16, 0xFFFFFFFF, LEFT);
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
		curHolding = 0;
		dragging = false;

		var txts = [for (opt in list) (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name))];
		var subs = [for (i => opt in list) getDesc(opt)];
		regenerate(txts, subs);
		this.list = list;

		while (components.length > 0)
			components.shift().destroy();

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
				case ListOption(options, true, translateItems):
					subTexts.members[i].fieldWidth -= 200;
					new DropdownText(opt, i == current);
				default:
					subTexts.members[i].fieldWidth -= 150;
					new Textbox(opt, i == current);
			}
			compon.position(texts.members[i], subTexts.members[i], selPercentages[i]);
			compon.clip(y, y + height);
			components.push(compon);
		}
		position(0);
	}

	public static function getDesc(opt:Option) {
		return (opt.desc.startsWith("<NO-LANG>") ? opt.desc.substring(9, opt.desc.length) : _formatT(opt.desc, [_t("accept").toUpperCase()]));
	}

	override function draw() {
		superDraw();
		// i'm sorry -Nebula
		hover.draw();
		//hover.blend = INVERT;
		//hover.draw();
		texts.draw();
		subTexts.draw();

		for (compon in components) {
			if (compon != null && compon.obj.visible)
				compon.drawInvertableCompon();
		}

		//hover.draw();
		//hover.blend = NORMAL;

		for (compon in components) {
			if (compon != null && compon.obj.visible)
				compon.drawRegularCompon();
		}
	}

	override function destroy() {
		super.destroy();
		while (components.length > 0)
			components.shift().destroy();
	}
}

interface OptionComponent<T:FlxSprite> {
	public var obj:T;

	public function hovering(idx:Int, opt:Option, list:OptionList, mousePoint:FlxPoint):Void;
	public function position(txt:FlxText, sub:FlxText, selPercent:Float):Void;
	public function clip(top:Float, bottom:Float):Void;
	public function change(opt:Option):Void;
	public function selectionChanged(opt:Option, selected:Bool):Void;

	public function drawRegularCompon():Void;
	public function drawInvertableCompon():Void;

	public function update(elapsed:Float):Void;
	public function destroy():Void;
}

class Checkbox extends FunkinSprite implements OptionComponent<Checkbox> {
	public var obj:Checkbox;

	public function hovering(idx:Int, opt:Option, list:OptionList, mousePoint:FlxPoint) {
		if (!FlxG.mouse.justPressed || !opt.hasEnter) return;

		if (opt.hasSound)
			FlxG.sound.play(Assets.audio("sfx/" + opt.sound));
		opt.enter();
		change(opt);

		if (list.onOptEnter != null)
			list.onOptEnter(idx);
	}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;

		setPosition(txt.x + txt.width - width, y + (height - this.height) * 0.5);
		scale.x = scale.y = 0.65 + 0.35 * selPercent;

		color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercent);
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
		frames = Assets.sparrowAtlas("images/menus/options/optionsbuttongay");
		animation.addByPrefix("true", "on", 24, false);
		animation.addByPrefix("totrue", "transition0", 24, false);
		animation.addByPrefix("false", "off", 24, false);
		animation.addByPrefix("tofalse", "transitionoff", 24, false);
		playAnim(Std.string(opt.value == true));
		
		animation.finishCallback = function(name) {
			if (name.startsWith("to"))
				playAnim(name.substring(2));
		};
		clipRect = FlxRect.get(0, 0, frameWidth, frameHeight);
	}

	public function drawRegularCompon() {}
	public function drawInvertableCompon() {draw();}
}

class Textbox extends FlxText implements OptionComponent<Textbox> {
	public var obj:Textbox;

	public function hovering(idx:Int, opt:Option, list:OptionList, mousePoint:FlxPoint) {
		if (!FlxG.mouse.justPressed) return;

		if (opt.hasSound)
			FlxG.sound.play(Assets.audio("sfx/" + opt.sound));

		var action:Int = -1; // -1 - None, 0 - Enter, 1 - Left, 2 - Right
		if (opt.textboxArrows && opt.hasEnter && opt.hasMove) {
			final leftRect = textField.getCharBoundaries(2);
			final rightRect = textField.getCharBoundaries(text.length - 2);

			var x = x - graphic.width * scale.x;
			if (mousePoint.x >= x + leftRect.x * scale.x && mousePoint.x <= x + rightRect.x * scale.x) {
				opt.enter();
				action = 0;
			} else {
				final isLeft = mousePoint.x <= x + leftRect.x * scale.x;
				list.curHolding = isLeft ? 3 : 4;
				list.holdWait = 0.5;
	
				opt.change(isLeft);
				action = isLeft ? 1 : 2;
			}
		} else if (opt.hasEnter && !opt.hasMove) {
			opt.enter();
			action = 0;
		} else if (!opt.hasEnter && opt.hasMove) {
			final isLeft = mousePoint.x <= x - graphic.width * scale.x * 0.5;
			list.curHolding = isLeft ? 3 : 4;
			list.holdWait = 0.5;

			opt.change(isLeft);
			action = isLeft ? 1 : 2;
		}
		change(opt);

		if (action == 0 && list.onOptEnter != null)
			list.onOptEnter(idx);
		else if (action > 0 && list.onOptMove != null)
			list.onOptMove(idx, action == 1);
	}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;

		regenGraphic();
		offset.x = origin.x = graphic.width;
		scale.x = scale.y = 0.5 + 0.5 * selPercent;
		setPosition(txt.x + txt.width, y + (height - this.height) * 0.5);

		color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercent);
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
		setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 40, 0xFFFFFFFF, RIGHT);
	}

	public function drawRegularCompon() {}
	public function drawInvertableCompon() {draw();}
}

class DropdownText extends FunkinSprite implements OptionComponent<DropdownText> {
	public var obj:DropdownText;
	var label:FlxText;

	public function hovering(idx:Int, opt:Option, list:OptionList, mousePoint:FlxPoint) {
		if (!FlxG.mouse.justPressed || !opt.hasEnter) return;

		if (opt.hasSound)
			FlxG.sound.play(Assets.audio("sfx/" + opt.sound));
		opt.enter();
		change(opt);

		if (list.onOptEnter != null)
			list.onOptEnter(idx);
	}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;

		this.scale.set(selPercent, selPercent);
		this.setPosition(txt.x + txt.width, y + (height - this.frameHeight) * 0.5);

		@:privateAccess label.regenGraphic();
		label.offset.x = label.origin.x = label.graphic.width;
		label.scale.x = label.scale.y = 0.5 + 0.5 * selPercent;
		label.setPosition(x - frameWidth * this.scale.x, this.y + (this.frameHeight - label.height) * 0.5);

		color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercent);
		label.color = color;
	}
	public function clip(top:Float, bottom:Float) {
		//Util.clipByCoords(this, null, null, top, bottom);
	}
	public function change(opt:Option):Void {
		label.text = opt.formatText(true);
	}
	public function selectionChanged(opt:Option, selected:Bool) {
		label.text = opt.formatText(selected);
	}

	public function new(opt:Option, selected:Bool) {
		super(0, 0, Assets.image("images/menus/options/optionsdropdowngay"));
		obj = this;

		origin.x = offset.x = frameWidth;

		label = new FlxText(0, 0, 0, opt.formatText(selected));
		label.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 40, 0xFFFFFFFF, RIGHT);
	}

	override function draw() {
		super.draw();
		label.draw();
	}

	public function drawRegularCompon() {}
	public function drawInvertableCompon() {
		draw();
		label.draw();
	}

	override function destroy() {
		super.destroy();
		label.destroy();
	}
}

class Slider extends FunkinSprite implements OptionComponent<Slider> {
	static inline final BAR_PADDING:Float = 4;

	public var obj:Slider;
	public var canInvert:Bool;
	var fillPercent:Float;
	var fill:FunkinSprite;
	var label:FlxText;
	var sliderScale:Float = 1;

	var min:Float;
	var max:Float;
	var snap:Float;

	public function hovering(idx:Int, opt:Option, list:OptionList, mousePoint:FlxPoint) {
		if (!list.dragging && (
			!FlxG.mouse.pressed ||
			mousePoint.x < x + BAR_PADDING * sliderScale ||
			mousePoint.x > x + scale.x - BAR_PADDING * sliderScale ||
			mousePoint.y < y + BAR_PADDING * sliderScale ||
			mousePoint.y > y + scale.y - BAR_PADDING * sliderScale
		)) return;

		list.dragging = FlxG.mouse.pressed;
		if (opt.hasSound && FlxG.mouse.justPressed)
			FlxG.sound.play(Assets.audio("sfx/" + opt.sound));

		// eh dont feel like Math.max(Math.min today
		final remapped = FlxMath.remapToRange(mousePoint.x, x + BAR_PADDING * label.scale.x, x + scale.x - BAR_PADDING * label.scale.x, min, max);
		opt.value = FlxMath.bound(Math.round(remapped * opt.powMult) / opt.powMult , min, max);
		change(opt);
	}
	public function position(txt:FlxText, sub:FlxText, selPercent:Float) {
		var y = txt.y - 5;
		var height = txt.height + (sub.height + 5) * selPercent;
		sliderScale = selPercent;

		this.scale.set(this.width * sliderScale, this.height * sliderScale);
		this.setPosition(txt.x + txt.width - this.scale.x, y + (height - this.scale.y) * 0.5);

		fill.scale.set(
			(this.width - BAR_PADDING * 2) * sliderScale * fillPercent,
			(this.height - BAR_PADDING * 2) * sliderScale
		);
		fill.setPosition(this.x + BAR_PADDING * sliderScale, this.y + BAR_PADDING * sliderScale);

		@:privateAccess label.regenGraphic();
		label.offset.x = label.origin.x = label.graphic.width;
		label.scale.x = label.scale.y = 0.65 + 0.35 * selPercent;
		label.setPosition(x, this.y + (this.scale.y - label.height) * 0.5);
		label.color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercent);
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
		color = 0xFF000000;

		final params = opt.type.getParameters();
		min = params[0];
		max = params[1];
		fillPercent = (opt.value - min) / (max - min);

		fill = new FunkinSprite();
		fill.makeGraphic(1, 1);
		fill.scale.set((width - BAR_PADDING * 2) * fillPercent, height - BAR_PADDING * 2);
		fill.updateHitbox();
		fill.origin.set();
		fill.offset.set();

		label = new FlxText(0, 0, 0, opt.formatText(selected));
		label.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 32, 0xFFFFFFFF, RIGHT);
	}

	public function drawRegularCompon() {
		draw();
		fill.draw();
	}
	public function drawInvertableCompon() {
		label.draw();
	}

	override function destroy() {
		super.destroy();
		fill.destroy();
		label.destroy();
	}
}