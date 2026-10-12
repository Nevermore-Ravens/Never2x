package funkin.substates;

import funkin.ui.AddonList;

class AddonsMenu extends FlxSubState {
	var wasVisible:Bool;
	var wasPersistant:Bool;
	var leftBox:AddonList;
	var rightBox:AddonList;
	var curBox:AddonList;

	var curAction:Int = 0;
	var actions:Array<String> = ["cancel", "open_folder", "refresh", "apply"];
	var actionTxt:FlxTypedGroup<FlxText>;
	var actionHover:FunkinSprite;
	// var actionInvertPrep:FunkinSprite;
	// var actionInvert:FunkinSprite;
	var actionPercentages:Array<Float>;

	public function new() {
		super();
		actionPercentages = [for (a in actions) 0.0];
		visible = false;
	}

	override function create() {
		visible = true;
		wasVisible = FlxG.mouse.visible;
		wasPersistant = parent.persistentUpdate;
		FlxG.mouse.visible = true;
		parent.persistentUpdate = false;
		cameras = [new FlxCamera()];
		FlxG.cameras.add(camera, false);

		var addonsOff = [for (addon in Addons.list) if (!addon.enabled) addon];
		var addonsOn = [for (addon in Addons.list) if (addon.enabled) addon];

		var bg = new FunkinSprite(0, FlxG.height * 0.5);
		bg.makeGraphic(1, 1, 0x80000000);
		bg.scale.set(FlxG.width, 0);
		bg.updateHitbox();
		add(bg);
		FlxTween.tween(bg.scale, {y: FlxG.height}, 0.25, {ease: FlxEase.cubeOut});

		add(leftBox = new AddonList(50, 100, 565, 520, addonsOff));
		leftBox.mouseCamera = camera;
		leftBox.displayHover = leftBox.allowKeys = addonsOff.length > 0;
		leftBox.allowDrag = false;
		leftBox.onRemoveAddon = function(addon, graphic) {
			rightBox.addAddon(addon, graphic);
			FlxG.sound.play(Assets.audio('sfx/scroll'));
			leftBox.displayHover = leftBox.allowKeys = leftBox.list.length > 1;
			rightBox.displayHover = rightBox.allowKeys = !leftBox.displayHover;
			curBox = leftBox.displayHover ? leftBox: rightBox;
		};
		leftBox.onSelect = function(cur, last) {
			FlxG.sound.play(Assets.audio('sfx/scroll'));
			leftBox.displayHover = leftBox.allowKeys = true;
			rightBox.displayHover = rightBox.allowKeys = false;
			curBox = leftBox;
		};
		add(rightBox = new AddonList(665, 100, 565, 520, addonsOn));
		rightBox.mouseCamera = camera;
		rightBox.displayHover = rightBox.allowKeys = addonsOff.length <= 0 && addonsOn.length > 0;
		rightBox.onRemoveAddon = function(addon, graphic) {
			leftBox.addAddon(addon, graphic);
			FlxG.sound.play(Assets.audio('sfx/scroll'));
			rightBox.displayHover = rightBox.allowKeys = rightBox.list.length > 1;
			leftBox.displayHover = leftBox.allowKeys = !rightBox.displayHover;
			curBox = leftBox.displayHover ? leftBox: rightBox;
		};
		rightBox.onSelect = function(cur, last) {
			FlxG.sound.play(Assets.audio('sfx/scroll'));
			leftBox.displayHover = leftBox.allowKeys = false;
			rightBox.displayHover = rightBox.allowKeys = true;
			curBox = rightBox;
		};
		curBox = leftBox.displayHover ? leftBox : rightBox;

		add(actionHover = new FunkinSprite());
		actionHover.makeGraphic(1, 1);
		actionHover.origin.set();
		actionHover.scale.set();

		// add(actionInvertPrep = new FunkinSprite());
		// actionInvertPrep.makeGraphic(1, 1);
		// actionInvertPrep.origin.set();
		// actionInvertPrep.scale.set();
		// actionInvertPrep.blend = INVERT;
		
		add(actionTxt = new FlxTypedGroup());
		for (i => act in actions) {
			var txt = new FlxText((FlxG.width / (actions.length + 1)) * (i + 1), 665, 0, _t(act));
			txt.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 28, 0xFFFFFFFF, CENTER);
			txt.x -= txt.width * 0.5;
			actionTxt.add(txt);
		}

		// add(actionInvert = new FunkinSprite());
		// actionInvert.makeGraphic(1, 1);
		// actionInvert.origin.set();
		// actionInvert.scale.set();
		// actionInvert.blend = INVERT;

		actionHover.scale.set(actionTxt.members[curAction].width + 10, actionTxt.members[curAction].height + 10);
		// actionInvertPrep.scale.copyFrom(actionHover.scale);
		// actionInvert.scale.copyFrom(actionHover.scale);
		actionHover.setPosition(actionTxt.members[curAction].x - 5, actionTxt.members[curAction].y - 5);
		// actionInvertPrep.setPosition(actionHover.x, actionHover.y);
		// actionInvert.setPosition(actionHover.x, actionHover.y);
	}

	override function update(delta:Float) {
		if (!visible) { // yes this is the differatiator b/w the plugin and substate
			if (FlxG.keys.justPressed.F4)
				FlxG.state.openSubState(new AddonsMenu());
			return;
		}
		
		leftBox.allowMouse = !rightBox.dragging;
		rightBox.allowMouse = !leftBox.dragging;
		var lastCurrent = curBox.current;
		super.update(delta);

		final upJustPressed = Controls.justPressed("ui_up");
		var inActions = !leftBox.displayHover && !rightBox.displayHover;
		if (inActions && (leftBox.list.length > 0 || rightBox.list.length > 0) && (upJustPressed || Controls.justPressed("ui_down"))) {
			inActions = false;
			curBox = curBox == leftBox && leftBox.list.length > 0 ? leftBox : rightBox;

			final idx = upJustPressed ? curBox.list.length - 1 : 0;
			if (lastCurrent == idx)
				curBox.onSelect(idx, idx);
			else
				curBox.retarget(idx);
		} else if (curBox.displayHover && !FlxG.keys.pressed.SHIFT && ((lastCurrent == 0 && upJustPressed) || (lastCurrent == curBox.list.length - 1 && Controls.justPressed("ui_down")))) {
			curBox.current = lastCurrent;
			inActions = true;
			FlxG.sound.play(Assets.audio("sfx/scroll"));
			curBox.displayHover = curBox.allowKeys = false;
		}
		
		var runAction = inActions && Controls.justPressed("accept");
		if ((leftBox.mouseMoved || rightBox.mouseMoved || FlxG.mouse.justPressed) && !leftBox.dragging && !rightBox.dragging) {
			for (i => act in actionTxt.members) {
				if (FlxG.mouse.screenX >= act.x - 5 && FlxG.mouse.screenX <= act.x + act.width + 5 && FlxG.mouse.screenY >= act.y - 5 && FlxG.mouse.screenY <= act.y + act.height + 5) {
					if (!inActions || curAction != i)
						FlxG.sound.play(Assets.audio('sfx/scroll'));
					curAction = i;
					inActions = true;
					leftBox.displayHover = leftBox.allowKeys = false;
					rightBox.displayHover = rightBox.allowKeys = false;
					runAction = runAction || FlxG.mouse.justPressed;
					break;
				}
			}
		}

		if (runAction) {
			switch (actions[curAction]) {
				case "cancel":
					close();
				case "open_folder":
					#if windows // do any of yall know any better solutions
					Sys.command("start", ["addons"]);
					#end
				case "refresh":
					Addons.reload();
					var lRemove = leftBox.onRemoveAddon;
					var rRemove = rightBox.onRemoveAddon;
					leftBox.onRemoveAddon = rightBox.onRemoveAddon = function(_, graphic) {FlxG.bitmap.remove(graphic);};
					while (leftBox.list.length > 0)
						leftBox.removeAddon(0);
					while (rightBox.list.length > 0)
						rightBox.removeAddon(0);

					for (addon in Addons.list)
						(!addon.enabled ? leftBox : rightBox).addAddon(addon);
					leftBox.onRemoveAddon = lRemove;
					rightBox.onRemoveAddon = rRemove;
				case "apply":
					Settings.data.addonsOff = [for (addon in leftBox.list) addon.directory];
					Settings.data.addonsOrder = [for (addon in rightBox.list) addon.directory];
					Addons.reload();
					Settings.save();
					FlxG.resetState();
			}
		}

		if (FlxG.keys.justPressed.F4 || Controls.justPressed("back"))
			close();

		final leftJustPressed = Controls.justPressed("ui_left");
		if (leftJustPressed || Controls.justPressed("ui_right")) {
			if (!inActions && leftBox.list.length > 0 && rightBox.list.length > 0) {
				final target = leftBox.displayHover ? rightBox : leftBox;
				final idx = Std.int(Math.min(curBox.current, target.list.length - 1));
				if (target.current == idx)
					target.onSelect(idx, idx);
				else
					target.retarget(idx);
			} else {
				FlxG.sound.play(Assets.audio("sfx/scroll"));
				curAction = (curAction + (leftJustPressed ? -1 : 1) + actions.length) % actions.length;
			}
		}

		actionHover.alpha = FlxMath.lerp(actionHover.alpha, (inActions ? 1 : 0), delta * 15);
		actionHover.scale.x = FlxMath.lerp(actionHover.scale.x, actionTxt.members[curAction].width + 10, delta * 15);
		// actionInvertPrep.scale.copyFrom(actionHover.scale);
		// actionInvert.scale.copyFrom(actionHover.scale);
		actionHover.x = FlxMath.lerp(actionHover.x, actionTxt.members[curAction].x - 5, delta * 15);
		// actionInvertPrep.setPosition(actionHover.x, actionHover.y);
		// actionInvert.setPosition(actionHover.x, actionHover.y);

		for (i in 0...actionPercentages.length) {
			actionPercentages[i] = FlxMath.lerp(actionPercentages[i], (i == curAction ? 1 : 0), delta * 15);
			actionTxt.members[i].color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, actionPercentages[i] * actionHover.alpha);
		}
	}

	override function destroy() {
		FlxG.mouse.visible = wasVisible;
		FlxG.state.persistentUpdate = wasPersistant;
		FlxG.cameras.remove(camera);
		super.destroy();
	}
}