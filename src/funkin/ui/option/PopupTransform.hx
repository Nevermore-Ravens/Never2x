package funkin.ui.option;

import funkin.states.OptionsState;
import funkin.ui.play.JudgeDisplay;
import funkin.ui.play.ComboDisplay;

import flixel.group.FlxSpriteGroup;

class PopupTransform extends OptionList {
	var judgeSprite:JudgeDisplay;
	var comboSprite:ComboDisplay;

	var draggingObj:FlxSprite = null;
	var dragMouseX:Float = 0;
	var dragMouseY:Float = 0;
	var dragObjX:Float = 0;
	var dragObjY:Float = 0;
	var dragX:Float = 0;
	var dragY:Float = 0;

	public function new(x:Float, y:Float, width:Float, height:Float) {
        super(x, y, width, height);

		judgeSprite = new JudgeDisplay(x - 10 + Settings.data.judgementPos[0], y - 10 + Settings.data.judgementPos[1]);
		judgeSprite.scaleBumped *= Settings.data.judgeScale;
		judgeSprite.scaleFlat *= Settings.data.judgeScale;
		judgeSprite.simple = true;//Settings.data.simplePopup;
		judgeSprite.x -= judgeSprite.width * 0.5;
		judgeSprite.y -= judgeSprite.height * 0.5;
		judgeSprite.display(0);

		comboSprite = new ComboDisplay(x - 10 + Settings.data.comboPos[0], y - 10 + Settings.data.comboPos[1]);
		comboSprite.scale.set(0.45 * Settings.data.comboScale, 0.45 * Settings.data.comboScale);
		comboSprite.simple = true;//judgeSprite.simple;
		comboSprite.colorMode = switch Settings.data.comboTinting {
			case "Per-Note": PER_NOTE;
			case "Clear Flag": CLEAR_FLAG;
			default: NONE;
		};
		comboSprite.display(0);

		setOptions([
			{
				var opt = new Option("<NO-LANG>Simple Popups", "<NO-LANG>Whether or not popups will simply bump and fade instead of jump and fall.", "simplePopup", BoolOption);
				opt.onChange = function(v) {
					judgeSprite.simple = v;	
					comboSprite.simple = v;	
				};
				opt;
			},
			new Option("<NO-LANG>Position Safety", "<NO-LANG>If the popup objects will recenter if overlapping a strumline.", "popupPosSafety", BoolOption),
			{
				var opt = new Option('<NO-LANE>Judgement Scale', '<NO-LANG>How big the judgement will be.', 'judgeScale', FloatOption(0.05, 3, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt.onChange = function(v) {
					judgeSprite.scaleBumped = 0.7 * Settings.data.judgeScale;
					judgeSprite.scaleFlat = 0.65 * Settings.data.judgeScale;
					judgeSprite.scale.set(judgeSprite.scaleFlat, judgeSprite.scaleFlat);
				}
				opt;
			},
			{
				var opt = new Option('<NO-LANG>Combo Scale', '<NO-LANG>How big the combo will be', 'comboScale', FloatOption(0.05, 3, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt.onChange = function(v) {
					comboSprite.scale.set(0.45 * Settings.data.comboScale, 0.45 * Settings.data.comboScale);
					for (i in 0...comboSprite.members.length) {
						var num = comboSprite.members[i];
						var centerI = i - comboSprite.length * 0.5;
						num.scale.copyFrom(comboSprite.scale);
						num.updateHitbox();
						num.x = comboSprite.x + ((num.width + comboSprite.spacing) * centerI);
					}
				}
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

	override function draw() {
		super.draw();
		judgeSprite.draw();
		comboSprite.draw();
	}
}