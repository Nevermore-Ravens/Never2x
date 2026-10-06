package funkin.objects.menu;

import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import funkin.backend.Addons;

class AddonList extends TextList {
	var icons:FlxTypedGroup<FunkinSprite>;
	var iconGraphics:Array<FlxGraphic> = [];
	var hoverHeight:Float = 30;
	var selPercentages:Array<Float> = [];
	
	var dragY:Float = 0;
	var dragOnce:Bool = false;
	public var dragging:Bool = false;
	public var allowDrag:Bool = true;
	public var list:Array<Addon> = [];

	public var onRemoveAddon:(addon:Addon, graphic:FlxGraphic)->Void;

	public function new(x:Float, y:Float, width:Float, height:Float, list:Array<Addon>) {
		super(x, y, width, height, []);
		icons = new FlxTypedGroup();

		hasSubTexts = true;
		for (addon in list)
			addAddon(addon);
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
			if (FlxG.keys.pressed.SHIFT)
				reorder(current, target);
			retarget(target);
		}

		if (Controls.justPressed('accept')) {
			removeAddon(current);
		}
	}

	override function mouseControl() {
		var y = y + 15 - curScroll;
		var off = dragging ? dragY : 0;
		for (i in 0...texts.length) {
			var height = (texts.members[current].height + (subTexts.members[current].height + 5) * selPercentages[i]);

			if (mousePoint.y - off >= y && mousePoint.y - off <= y + height && canSelect(i)) {
				if (dragging && i != current) {
					dragOnce = true;
					reorder(i, current);
				} else if (FlxG.mouse.justPressed) {
					dragging = true;
					dragY = mousePoint.y - texts.members[i].y;
				}

				retarget((mouseMoved || dragging || FlxG.mouse.justPressed) ? i : current);
				if (onSelect != null && !displayHover)
					onSelect(current, current);

				if (FlxG.mouse.justReleased && !dragOnce)
					removeAddon(current);

				if (!dragging)
					break;
			}
			y += height;
		}

		if (FlxG.mouse.justReleased) {
			dragging = false;
			dragOnce = false;
		}
	}

	override function position(elapsed:Float) {
		if (dragging && allowMouse && (mousePoint.x < x || mousePoint.x > x + scale.x))
			mouseControl();

		curScroll = FlxMath.lerp(curScroll, scrollInc * current, elapsed * 15);
		var y = y + 15 - curScroll;
		for (i in 0...texts.length) {
			var offset = 0.0;
			final txt = texts.members[i];
			final sub = subTexts.members[i];
			selPercentages[i] = FlxMath.lerp(selPercentages[i], (i == current && displayHover ? 1 : 0), elapsed * 15);
			if (iconGraphics[i] != null) {
				final icon = icons.members[i];
				
				offset = FlxMath.lerp(icon.graphic.height * icon.scale.y, FlxMath.lerp(txt.height - 5, icon.height, selPercentages[i]), elapsed * 15);
				icon.scale.x = icon.scale.y = offset / icon.graphic.height;
				offset += 5;

				icon.setPosition(x + 15, (dragging && i == current) ? mousePoint.y - dragY : FlxMath.lerp(icon.y, y, elapsed * 20));
				Util.clipByCoords(icon, null, null, this.y, this.y + scale.y);
			}

			txt.setPosition(x + 15 + offset, (dragging && i == current) ? mousePoint.y - dragY : FlxMath.lerp(txt.y, y, elapsed * 20));
			txt.alpha = alpha;
			Util.clipByCoords(txt, null, null, this.y, this.y + scale.y);
			txt.color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercentages[i]);
			
			sub.setPosition(txt.x, txt.y + (txt.height - 5) * selPercentages[i]);
			sub.alpha = alpha * selPercentages[i];
			Util.clipByCoords(sub, null, null, this.y, this.y + scale.y);
			sub.color = txt.color;

			y += txt.height + (sub.height + 5) * selPercentages[i];
		}
		var targetHeight = 0.0;
		if (texts.length > 0) {
			scrollInc = Math.max((y + curScroll - this.y - 15 + 60) - height, 0) / texts.length;
			targetHeight = (texts.members[current].height + (subTexts.members[current].height - 5) * selPercentages[current]) + 10;
			hoverY = FlxMath.lerp(hoverY, texts.members[current].y - 5, elapsed * 15);
			hover.setPosition(x, hoverY);
		} else
			scrollInc = 0;
		hoverHeight = FlxMath.lerp(hoverHeight, targetHeight, elapsed * 15);
		hover.alpha = FlxMath.lerp(hover.alpha, displayHover ? alpha : 0, elapsed * 15);

		hover.scale.y = hoverHeight;
		hover.scale.y -= Math.max((hover.y + hoverHeight) - (this.y + scale.y), 0);
		var topClip = Math.max(this.y - hover.y, 0);
		hover.y += topClip;
		hover.scale.y -= topClip;
		hover.scale.y = Math.max(hover.scale.y, 0);
	}

	public function reorder(from:Int, to:Int) {
		final txt = texts.members[from];
		texts.remove(txt, true);
		texts.insert(to, txt);
		final sub = subTexts.members[from];
		subTexts.remove(sub, true);
		subTexts.insert(to, sub);
		final icon = icons.members[from];
		icons.remove(icon, true);
		icons.insert(to, icon);

		final addon = list[from];
		list.remove(addon);
		list.insert(to, addon);
		final graphic = iconGraphics[from];
		iconGraphics.splice(from, 1);
		iconGraphics.insert(to, graphic);
	}

	override function regenerate(txts:Array<String>, ?subs:Array<String>) {} // dont you fuck shit up
	public function addAddon(addon:Addon, ?graphic:FlxGraphic) {
		list.push(addon);
		var y = (texts.length > 0) ? texts.members[texts.length - 1].height + (subTexts.members[texts.length - 1].height - 5) * selPercentages[texts.length - 1] : y + 15 - curScroll;
		selPercentages.push(0);

		if (graphic == null && FileSystem.exists('addons/${addon.directory}/icon.png')) {
			var bitmapO = BitmapData.fromFile('addons/${addon.directory}/icon.png');
			if (bitmapO.width != bitmapO.height) {
				var minSize = Std.int(Math.min(bitmapO.width, bitmapO.height));
				var rect = new openfl.geom.Rectangle((bitmapO.width - minSize) * 0.5, (bitmapO.height - minSize) * 0.5, minSize, minSize);
				var newBitmap = new BitmapData(minSize, minSize, true, 0);
				newBitmap.draw(bitmapO, rect);
				bitmapO.dispose();
				bitmapO = newBitmap;
			}
			//if (Settings.data.gpuCache) openfl.utils.BitmapDataUtil.toHardware(bitmapO);
			graphic = FlxGraphic.fromBitmapData(bitmapO, false, 'addons/${addon.directory}/icon.png');
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
		}
		iconGraphics.push(graphic);
		
		var icon = new FunkinSprite(x + 15, y, graphic);
		icon.visible = graphic != null;
		icons.add(icon);

		var txt = new FlxText(x + 15, y, 0, "_");
		txt.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 24, 0xFFFFFFFF, LEFT);
		txt.antialiasing = Settings.data.antialiasing;
		texts.add(txt);

		var sub = new FlxText(txt.x, txt.y, 0, "_");
		sub.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 16, 0xFFFFFFFF, LEFT);
		sub.antialiasing = Settings.data.antialiasing;
		subTexts.add(sub);
		sub.alpha = 0;

		if (graphic != null) {
			icon.setGraphicSize(0, txt.height + sub.height - 5);
			icon.updateHitbox();
			icon.origin.set();
			icon.offset.set();
			icon.setGraphicSize(0, txt.height - 5);

			txt.fieldWidth = width - 30 - icon.height - 5;
			sub.fieldWidth = width - 30 - icon.height - 5;
			txt.x += txt.height + 5;
			sub.x += txt.height + 5;
		} else {
			txt.fieldWidth = width - 30;
			sub.fieldWidth = width - 30;
		}
		txt.text = addon.name;
		sub.text = addon.description;

		y += txt.height;
		scrollInc = Math.max((y - (this.y + 15 - curScroll) + 60) - height, 0) / texts.length;
		current = texts.length - 1;
	}
	public function removeAddon(idx:Int) {
		final txt = texts.members[idx];
		texts.remove(txt, true);
		txt.destroy();
		final sub = subTexts.members[idx];
		subTexts.remove(sub, true);
		sub.destroy();
		final icon = icons.members[idx];
		icons.remove(icon, true);
		icon.destroy();

		if (onRemoveAddon != null)
			onRemoveAddon(list[idx], iconGraphics[idx]);
		selPercentages.splice(idx, 1);
		list.splice(idx, 1);
		iconGraphics.splice(idx, 1);

		scrollInc = texts.length > 0 ? Math.max((y - (this.y + 15 - curScroll) + 60) - height, 0) / texts.length : 0;
		current = texts.length > 0 ? Std.int(FlxMath.bound(current, 0, texts.length - 1)) : 0;
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
		icons.draw();
	}

	override function destroy() {
		for (graph in iconGraphics)
			FlxG.bitmap.remove(graph);

		super.destroy();
		// while (components.length > 0)
		// 	components.shift().destroy();
	}
}