package funkin.objects.menu;

class TextList extends FunkinSprite {
	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	public var mouseMoved:Bool = false;
	
	public var autoColor:Bool = true;
	public var texts:FlxTypedGroup<FlxText>;
	public var subTexts:FlxTypedGroup<FlxText>;
	var hasSubTexts:Bool = false;
	var hover:FunkinSprite;

	var curScroll:Float = 0;
	var scrollInc:Float = 0;

	public var current:Int = 0;

	var hoverTmr:Float = 0;
	public var hovered(get, never):Bool;
	public var allowKeys:Bool = true;
	public var allowMouse:Bool = true;

	public var onClick:(current:Int)->Void;
	public var onSelect:(current:Int, last:Int)->Void;
	public var onAccept:(current:Int)->Void;

	dynamic public function canSelect(target:Int) {return true;}

	public function new(x:Float, y:Float, width:Float, height:Float, txts:Array<String>, ?subs:Array<String>) {
		super(x, y);
		active = true;
		makeGraphic(1, 1, 0x80000000);
		this.width = width;
		this.height = height;
		origin.set();

		hover = new FunkinSprite(x, y);
		hover.makeGraphic(1, 1, 0xFFFFFFFF);
		hover.scale.set(width, 30);
		hover.origin.set();

		texts = new FlxTypedGroup();
		subTexts = new FlxTypedGroup();
		regenerate(txts, subs);
	}

	public function regenerate(txts:Array<String>, ?subs:Array<String>) {
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

		current = 0;
		var y = y + 15;
		for (i in 0...txts.length) {
			var txt = new FlxText(x + 15, y, width - 30, txts[i]);
			txt.setFormat(Paths.font("cafeSquare.ttf"), 24, (i != current ?0xFFFFFFFF : 0xFF101010), LEFT);
			txt.antialiasing = Settings.data.antialiasing;
			texts.add(txt);

			if (hasSubTexts) {
				var sub = new FlxText(txt.x, txt.y, width - 30, subs[i]);
				sub.setFormat(Paths.font("vcr.ttf"), 24, (i != current ?0xFFFFFFFF : 0xFF101010), RIGHT);
				sub.antialiasing = Settings.data.antialiasing;
				subTexts.add(sub);
			}

			y += 30;
		}
		scrollInc = Math.max(txts.length * 30 + 30 - height, 0) / txts.length;
	}

	public function setText(target:Int, text:String)
		texts.members[target].text = text;
	public function setSubText(target:Int, text:String)
		subTexts.members[target].text = text;

	function retarget(target:Int) {
		if (current == target) return;

		var last:Int = current;
		current = target;

		if (onSelect != null)
			onSelect(current, last);
	}

	override function update(elapsed:Float) {
		mouseMoved = false;
		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;
			mouseMoved = true;
		}
		
		hoverTmr -= elapsed;
		if (allowMouse && FlxG.mouse.x >= x && FlxG.mouse.x <= x + width) {
			hoverTmr = mouseMoved ? 2 : hoverTmr;

			for (i in 0...texts.length) {
				var top = y + 15 + 30 * i;
	
				if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + 30 && canSelect(i)) {
					retarget((mouseMoved || FlxG.mouse.justPressed) ? i : current);
	
					if (FlxG.mouse.justPressed && onClick != null)
						onClick(i);
					break;
				}
			}
		} else
			hoverTmr = 0;

		if (allowKeys) {
			final downJustPressed:Bool = Controls.justPressed('ui_down');
	
			if (downJustPressed || Controls.justPressed('ui_up')) {
				final firstNew = FlxMath.wrap(current + (downJustPressed ? 1 : -1), 0, texts.length - 1);
				var target = firstNew;
				while (!canSelect(target)) {
					target = FlxMath.wrap(target + (downJustPressed ? 1 : -1), 0, texts.length - 1);
					if (target == firstNew)
						break; // safety
				}
				retarget(target);
			}

			if (Controls.justPressed('accept') && onAccept != null)
				onAccept(current);
		}

		curScroll = FlxMath.lerp(curScroll, scrollInc * current, elapsed * 15);
		hover.y = FlxMath.lerp(hover.y, y + 15 + curScroll + 30 * current, elapsed * 15);
		hover.alpha = alpha;
		for (i in 0...texts.length) {
			final txt = texts.members[i];
			txt.setPosition(x + 15, y + 15 + curScroll + 30 * i);
			txt.alpha = alpha;
			if (autoColor)
				txt.color = FlxColor.interpolate(txt.color, (i == current) ? 0xFF101010 : 0xFFFFFFFF, elapsed * 25);
			
			if (hasSubTexts) {
				final sub = subTexts.members[i];
				sub.setPosition(txt.x, txt.y);
				sub.alpha = alpha;
				if (autoColor)
					sub.color = txt.color;
			}
		}
	}

	function get_hovered()
		return hoverTmr > 0;

	override function set_width(to:Float) {
		if (scale != null)
			scale.x = to;
		return width = to;
	}
	override function set_height(to:Float) {
		if (scale != null)
			scale.y = to;
		return height = to;
	}

	override function draw() {
		super.draw();
		hover.draw();
		texts.draw();
		subTexts.draw();
	}
}