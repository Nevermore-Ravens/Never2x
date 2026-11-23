package funkin.ui.option;

import nevermore.play.Strumline;
import funkin.states.OptionsState;
import funkin.ui.play.JudgeDisplay;
import funkin.ui.play.ComboDisplay;

import flixel.group.FlxSpriteGroup;

class PopupTransform extends OptionList {
	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	var judgeSprite:JudgeDisplay;
	var comboSprite:ComboDisplay;

	var draggingObj:FlxSprite = null;
	var dragMouseX:Float = 0;
	var dragMouseY:Float = 0;
	var dragObjX:Float = 0;
	var dragObjY:Float = 0;
	var dragX:Float = 0;
	var dragY:Float = 0;

	var overlapWarning:FlxText;
	var overlapsJudge:Bool = false;
	var overlapsCombo:Bool = false;
	var dangerTmr:Float = 0;

	public function setObjAlpha(to:Float) {
		judgeSprite.alpha = to;
		comboSprite.alpha = to;

		leftStrumline.alpha = Math.max(to * 0.5, 0.001); // cap it for proper memory
		rightStrumline.alpha = Math.max(to * 0.5, 0.001);
	}
	public function resetPopupPos() {
		var target = Settings.data.gameplayModifiers["playingSide"] == "Opponent" ? leftStrumline : rightStrumline;
		var popupX:Float = (Settings.data.popupOnField ? target.x : x - 10);

		judgeSprite.setPosition(popupX + Settings.data.judgementPos[0] - judgeSprite.width * 0.5, y - 10 + Settings.data.judgementPos[1] - judgeSprite.height * 0.5);
		comboSprite.setPosition(popupX + Settings.data.comboPos[0], y - 10 + Settings.data.comboPos[1]);
		checkOverlap();
	}
	public function resetStrumlines() {
		var skin = Settings.data.noteSkin;
		var style = Settings.data.noteSkinStyle;

		var meta = NoteStyling.getSkinMeta(skin);
		style = style != "default" && meta.styleNames.exists(style) ? style : meta.styleKeys[0];
		var skin = NoteStyling.getSkinAndStyle(skin, style);

		var strumlineHeight:Float = skin.spacing * Settings.data.strumSize;
		var strumlineYPos:Float = y + (Settings.data.downscroll ? height - 50 - strumlineHeight : 50);
		var isOpp = Settings.data.gameplayModifiers["playingSide"] == "Opponent";

		leftStrumline.visible = isOpp || (Settings.data.opponentNotes && !Settings.data.centeredNotes);
		if (leftStrumline.visible) {
			NoteStyling.switchFieldSkin(leftStrumline, skin);
			leftStrumline.size = Settings.data.strumSize;
			leftStrumline.y = strumlineYPos;
			leftStrumline.x = x + width * (Settings.data.centeredNotes ? 0.5 : 0.25);
		}
		
		rightStrumline.visible = !isOpp || (Settings.data.opponentNotes && !Settings.data.centeredNotes);
		if (rightStrumline.visible) {
			NoteStyling.switchFieldSkin(rightStrumline, skin);
			rightStrumline.size = Settings.data.strumSize;
			rightStrumline.y = strumlineYPos;
			rightStrumline.x = x + width * (Settings.data.centeredNotes ? 0.5 : 0.75);
		}

		resetPopupPos();
	}

	public function new(x:Float, y:Float, width:Float, height:Float) {
        super(x, y, width, height);

		var skin = Settings.data.noteSkin;
		var style = Settings.data.noteSkinStyle;

		var meta = NoteStyling.getSkinMeta(skin);
		style = style != "default" && meta.styleNames.exists(style) ? style : meta.styleKeys[0];
		var skin = NoteStyling.getSkinAndStyle(skin, style);

		leftStrumline = new Strumline(0, 0, skin);
		leftStrumline.scrollFactor.set(1, 1);
		leftStrumline.alpha = 0.5;
		rightStrumline = new Strumline(0, 0, skin);
		rightStrumline.scrollFactor.set(1, 1);
		rightStrumline.alpha = 0.5;

		judgeSprite = new JudgeDisplay();
		judgeSprite.scaleBumped *= Settings.data.judgeScale;
		judgeSprite.scaleFlat *= Settings.data.judgeScale;
		judgeSprite.scale.set(judgeSprite.scaleFlat, judgeSprite.scaleFlat);
		judgeSprite.updateHitbox();
		judgeSprite.simple = true;//Settings.data.simplePopup;
		judgeSprite.x -= judgeSprite.width * 0.5;
		judgeSprite.y -= judgeSprite.height * 0.5;
		judgeSprite.display(0);

		comboSprite = new ComboDisplay();
		comboSprite.scale.set(0.45 * Settings.data.comboScale, 0.45 * Settings.data.comboScale);
		comboSprite.simple = true;//judgeSprite.simple;
		comboSprite.colorMode = switch Settings.data.comboTinting {
			case "Per-Note": PER_NOTE;
			case "Clear Flag": CLEAR_FLAG;
			default: NONE;
		};
		comboSprite.display(0);

		overlapWarning = new FlxText(x, y + height - 15, width, getText("popup_pos_warning"));
		overlapWarning.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 20, 0xFFFFFFFF, CENTER);
		overlapWarning.setBorderStyle(OUTLINE, 0xFF000000, 2);
		overlapWarning.y -= overlapWarning.height;

		resetStrumlines();

		setOptions([
			{
				var opt = new Option("simple_popups", "simple_popups_desc", "simplePopup", BoolOption);
				opt.onChange = function(val:Bool) {
					judgeSprite.simple = val;	
					comboSprite.simple = val;	
				};
				opt;
			},
			new Option("position_safety", "position_safety_desc", "popupPosSafety", BoolOption),
			{
				var opt = new Option("popup_on_field", "popup_on_field_desc", "popupOnField", BoolOption);
				opt.onChange = function(_) {
					resetPopupPos();
				};
				opt;
			},
			{
				var opt = new Option('judgement_scale', 'judgement_scale_desc', 'judgeScale', FloatOption(0.05, 3, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt.onChange = function(val:Float) {
					judgeSprite.scaleBumped = 0.7 * val;
					judgeSprite.scaleFlat = 0.65 * val;
					judgeSprite.scale.set(judgeSprite.scaleFlat, judgeSprite.scaleFlat);

					judgeSprite.x -= (judgeSprite.frameWidth * judgeSprite.scale.x - judgeSprite.width) * 0.5;
					judgeSprite.y -= (judgeSprite.frameHeight * judgeSprite.scale.y - judgeSprite.height) * 0.5;
					judgeSprite.updateHitbox();

					checkOverlap();
				}
				opt;
			},
			{
				var opt = new Option('combo_scale', 'combo_scale_desc', 'comboScale', FloatOption(0.05, 3, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt.onChange = function(val:Float) {
					comboSprite.scale.set(0.45 * val, 0.45 * val);
					for (i in 0...comboSprite.members.length) {
						var num = comboSprite.members[i];
						var centerI = i - comboSprite.length * 0.5;
						num.scale.copyFrom(comboSprite.scale);
						num.updateHitbox();
						num.x = comboSprite.x + ((num.width + comboSprite.spacing) * centerI);
					}

					checkOverlap();
				}
				opt;
			},
			{
				var opt = new Option("apply_preset", "apply_preset_desc", "", ButtonOption);

				var optionList = ["Cancel", "Funkin'", "Centered", "Field-Centered", "In-Between"];

				opt.onChange = function(_) {
					var x:Float = mousePoint.x;
					var y:Float = mousePoint.y;
					if (Controls.justPressed("accept")) {
						@:privateAccess var hover = hover;
						x = hover.x + hover.scale.x;
						y = hover.y + hover.scale.y;
					}

					FlxG.state.persistentUpdate = false;
					FlxG.state.openSubState(new DropdownPrompt(x, y, 250, optionList, function(idx) {
						FlxG.sound.play(Assets.audio("sfx/scroll"), Settings.data.sfxVolume);

						inline function setPos(judgeX:Float, judgeY:Float, comboX:Float, comboY:Float) {
							Settings.data.judgementPos[0] = judgeX;
							Settings.data.judgementPos[1] = judgeY;
							Settings.data.comboPos[0] = comboX;
							Settings.data.comboPos[1] = comboY;
						}

						switch idx {
							case 1: // Funkin'
								setPos(530, 350, 450, 420);
								setOptionValue("simplePopup", false);
								setOptionValue("judgeScale", 1);
								setOptionValue("comboScale", 1);
								setOptionValue("popupOnField", false);
							case 2: // Centered
								setPos(640, 360, 640, 420);
								setOptionValue("judgeScale", 1);
								setOptionValue("comboScale", 1);
								setOptionValue("popupOnField", false);
							case 3: // Field-Centered
								setPos(0, 360, 0, 420);
								setOptionValue("judgeScale", 1);
								setOptionValue("comboScale", 1);
								setOptionValue("popupOnField", true);
							case 4: // In-Between
								setPos(640, 100, 640, 150);
								setOptionValue("simplePopup", true);
								setOptionValue("popupPosSafety", Settings.data.centeredNotes);
								setOptionValue("judgeScale", 0.85);
								setOptionValue("comboScale", 0.85);
								setOptionValue("popupOnField", false);
						}
					}));
				};
				opt;
			}
		]);
	}

	override function mouseControl() {
		for (mem in comboSprite.members)
			mem.visibility = Settings.data.comboAlpha;
		@:privateAccess judgeSprite.visibility = Settings.data.judgementAlpha;

		var judgeHovered = FlxG.mouse.overlaps(judgeSprite, mouseCamera);
		var comboHovered = FlxG.mouse.overlaps(comboSprite, mouseCamera);

		if (draggingObj != null || judgeHovered || comboHovered) {
			focused = false;

			if (FlxG.mouse.justPressed) {
				var arr = judgeHovered ? Settings.data.judgementPos : Settings.data.comboPos;
				var obj = judgeHovered ? judgeSprite : comboSprite;

				draggingObj = obj;
				dragMouseX = mousePoint.x;
				dragMouseY = mousePoint.y;
				dragObjX = obj.x;
				dragObjY = obj.y;
				dragX = arr[0];
				dragY = arr[1];
			}
			if (draggingObj != null) {
				var arr = draggingObj == judgeSprite ? Settings.data.judgementPos : Settings.data.comboPos;
				
				var diffX = mousePoint.x - dragMouseX;
				var diffY = mousePoint.y - dragMouseY;
				draggingObj.x = dragObjX + diffX;
				draggingObj.y = dragObjY + diffY;
				arr[0] = dragX + diffX;
				arr[1] = dragY + diffY;

				checkOverlap();
				if (!FlxG.mouse.pressed)
					draggingObj = null;
			}

			return;
		}
		focused = true;

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

	override function resetText() {
		super.resetText();
		overlapWarning.text = getText("popup_pos_warning");
	}

	function checkOverlap() {
		var target = Settings.data.gameplayModifiers["playingSide"] == "Opponent" ? leftStrumline : rightStrumline;
		
		var comboNum = comboSprite.members[0];
		var strumlineHeight:Float = target.skin.spacing * Settings.data.strumSize;
		var comboLeft = comboSprite.x + (comboNum.width + comboSprite.spacing) * (-comboSprite.length * 0.5);
		var comboRight = comboSprite.x + (comboNum.width + comboSprite.spacing) * (comboSprite.length * 0.5);
		
		// long
		overlapsJudge = judgeSprite.x < target.findMaxX() && judgeSprite.x + judgeSprite.width > target.findMinX() 
							&& judgeSprite.y < target.y + strumlineHeight + 20 && judgeSprite.y + judgeSprite.height > target.y - 20;
		overlapsCombo = comboLeft < target.findMaxX() && comboRight > target.findMinX()
							&& comboSprite.y < target.y + strumlineHeight + 20 && comboSprite.y + comboNum.height > target.y - 20;
		var distance = FlxMath.vectorLength(comboSprite.x - judgeSprite.x, comboSprite.y - judgeSprite.y);

		overlapsJudge = overlapsJudge || (overlapsCombo && distance <= 75);
		overlapsCombo = overlapsCombo || (overlapsJudge && distance <= 75);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		dangerTmr += elapsed;
		var dangerSin = 0.5 + 0.5 * Math.sin(dangerTmr * Math.PI);

		overlapWarning.color = FlxColor.interpolate(0xFFFF0A37, 0xFFFF2667, dangerSin);
		judgeSprite.color = FlxColor.interpolate(0xFFFFFFFF, 0xFFFF2667, (Settings.data.popupPosSafety && overlapsJudge) ? dangerSin : 0);
		var comboCol = FlxColor.interpolate(0xFFFFFFFF, 0xFFFF2667, (Settings.data.popupPosSafety && overlapsCombo) ? dangerSin : 0);
		for (comb in comboSprite.members)
			comb.color = comboCol;
	}

	override function destroy() {
		super.destroy();
		leftStrumline.destroy();
		rightStrumline.destroy();
		judgeSprite.destroy();
		comboSprite.destroy();
	}

	override function draw() {
		super.draw();
		if (leftStrumline.visible)
			leftStrumline.draw();
		if (rightStrumline.visible)
			rightStrumline.draw();
		judgeSprite.draw();
		comboSprite.draw();

		if (Settings.data.popupPosSafety && (overlapsJudge || overlapsCombo))
			overlapWarning.draw();
	}
}