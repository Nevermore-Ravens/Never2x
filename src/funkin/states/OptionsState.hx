package funkin.states;

import funkin.ui.TextList;
import funkin.ui.option.OptionList;
import funkin.ui.option.NoteCustomization;
import funkin.ui.option.PopupTransform;
import funkin.objects.FunkinSprite;
import funkin.core.Settings.SaveVariables;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;

class OptionsState extends FunkinState {
	public static var self:OptionsState;

	final categoryList:Array<String> = ["Keybinds", "Gameplay", "HUD", "Visuals", "Performance", "Misc."];
	final optionsList:Map<String, Array<Option>> = [
		"Keybinds" => [
            {
    			var opt = new Option("swap_keybind_mode_generic", "swap_keybind_mode_desc", "", ButtonOption);
				opt.formatText = function(selected) {
					return selected ? (self.controllerMode ? "Edit Keys" : "Edit Buttons") : "";
				}
    			opt.onChange = function(_) {
                    self.controllerMode = !self.controllerMode;

         			final prevCategory:Int = self.selCategory;
         			self.selCategory = -1; // force a regen of the menu cuz Fuck
         			self.openCategory(prevCategory);
                };
    			opt;
    		},
			new Option("", "", "", Unselectable),
			new Option("left_note", "left_note_desc", "note_left", KeyOption),
			new Option("down_note", "down_note_desc", "note_down", KeyOption),
			new Option("up_note", "up_note_desc", "note_up", KeyOption),
			new Option("right_note", "right_note_desc", "note_right", KeyOption),
			new Option("pause", "pause_desc", "pause", KeyOption),
			new Option("reset", "reset_desc", "reset", KeyOption),
			new Option("", "", "", Unselectable),
			new Option("ui_left", "ui_left_desc", "ui_left", KeyOption),
			new Option("ui_down", "ui_down_desc", "ui_down", KeyOption),
			new Option("ui_up", "ui_up_desc", "ui_up", KeyOption),
			new Option("ui_right", "ui_right_desc", "ui_right", KeyOption),
			new Option("accept", "accept_desc", "accept", KeyOption),
			new Option("back", "back_desc", "back", KeyOption),
			new Option("", "", "", Unselectable),
			{
				var opt = new Option("mute", "mute_desc", "volume_mute", KeyOption);
				opt.onChange = function(v) {
					// reverse the function before settings as this gets inputted after setting.
					FlxG.sound.toggleMuted();
				}
				opt;
			},
			{
				var opt = new Option("volume_up", "volume_up_desc", "volume_up", KeyOption);
				opt.onChange = function(v) {
					// reverse the function before settings as this gets inputted after setting.
					FlxG.sound.changeVolume(-0.1);
				}
				opt;
			},
			{
				var opt = new Option("volume_down", "volume_down_desc", "volume_down", KeyOption);
				opt.onChange = function(v) {
					// reverse the function before settings as this gets inputted after setting.
					FlxG.sound.changeVolume(0.1);
				}
				opt;
			}
			// ill not add the debug keys
		],
		"Gameplay" => [
			{
				var opt = new Option('scroll_dir', 'scroll_dir_desc', "scrollDirection", ListOption(["Up", "Down"]));
				opt;
			},
			{
				var opt = new Option('scroll_speed', 'scroll_speed_desc', "scrollSpeed", FloatOption(0.5, 7, 0.05));
				opt;
			},
			{
				var opt = new Option('customize_notes', 'customize_notes_desc', "", ButtonOption);
				opt.hasSound = true;
				opt.onChange = function(_) {
					self.lastList = self.targetList;
					self.targetList = self.noteEdit;
				};
				opt;
			},
			{
				var opt = new Option('note_offset', 'note_offset_desc', "inputOffset", FloatOption(-5000, 5000, 1));
				opt.formatText = function(_) {
					return opt.value + " MS";
				};
				opt;
			},
			new Option('ghost_t', 'ghost_t_desc', "ghostTapping", BoolOption),
			new Option('metronome', 'metronome_desc', "metronome", BoolOption),
			new Option('assist_claps', 'assist_claps_desc', "assistTicks", BoolOption),
			new Option('can_reset', 'can_reset_desc', "canReset", BoolOption),
			//new Option('acc_type', 'acc_type_desc', "accuracyType", ListOption(["Simple", "Complex"]))
			//i'm gonna be honest, all complex acc does is make ranking inconsistent, given how we have
			//standardized score based on judgements now i really don't see a need to have complex acc at all -fox
		],
		"HUD" => [
			new Option("judge_counter", "judge_counter_desc", "judgementCounter", BoolOption),
			new Option('hit_error_bar', 'hit_error_bar_desc', "hitErrorBar", BoolOption),
			new Option("combo_tinting", "combo_tinting_desc", "comboTinting", ListOption(["Off", "Clear Flag", "Per-Note"], true)),
			{
				var opt = new Option("<NO-LANG>Repositon Popups", "<NO-LANG>", "", ButtonOption);
				opt.hasSound = true;
				opt.onChange = function(_) {
					self.lastList = self.targetList;
					self.targetList = self.popupEdit;
				};
				opt;
			},
			new Option("time_text", "time_text_desc", "timeText", BoolOption),
			new Option("hide_acc", "hide_acc_desc", "hideAcc", BoolOption),
			new Option("hide_hud", "hide_hud_desc", "hideHUD", BoolOption),
			new Option("hide_tightest_judge", "hide_tightest_judge_desc", "hideTightestJudge", BoolOption),
			{
				var opt = new Option("judge_alpha", "judge_alpha_desc", "judgementAlpha", FloatOption(0, 1, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			},
			{
				var opt = new Option("combo_alpha", "combo_alpha_desc", "comboAlpha", FloatOption(0, 1, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			},
			{
				var opt = new Option("hp_alpha", "hp_alpha_desc", "healthBarAlpha", FloatOption(0, 1, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			}
		],
		"Visuals" => [
			{
				var opt = new Option('language', 'language_desc', "language", ListOption(LanguageHandler.getLanguages(), true));
				opt.onChange = function(v) {
					LanguageHandler.setLanguage(v);
					for (i => cate in self.categoryList)
						self.cateText.setText(i, _t(cate));

					for (i => opt in self.curOptList) {
						final opt = self.curOptList[i];
						self.optText.setText(i, opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name));
						self.optText.setSubText(i, OptionList.getDesc(opt));
						// self.optText.setSubText(i, opt.formatText(i == self.optText.current));
					}
				}
				opt;
			},
			new Option("flashing_lights", "flashing_lights_desc", "flashingLights", BoolOption),
			{
				var opt = new Option('strum_size', 'strum_size_desc', 'strumSize', FloatOption(0.05, 3, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			},
			new Option('center_notes', 'center_notes_desc', "centeredNotes", BoolOption),
			new Option('opp_notes', 'opp_notes_desc', "opponentNotes", BoolOption),
			{
				var opt = new Option('lane_underlay', 'lane_underlay_desc', 'laneUnderlay', FloatOption(0, 1, 0.05, false, true));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			},
			new Option("cam_zooms", "cam_zooms_desc", "cameraZooms", ListOption(["Default", "Off"], true)),
			new Option("cam_movement", "cam_movement_desc", "notesMoveCamera", BoolOption),
			new Option('strum_glow', 'strum_glow_desc', 'strumGlow', ListOption(['Off', 'Judgement', 'Note'], true)),
			new Option("can_unglow", "can_unglow_desc", "unglowOnAnimFinish", BoolOption),
		],
		"Performance" => [
			{
				var opt = new Option("framerate", "framerate_desc", "framerate", IntOption(15, 1000, 5));
				opt.onChange = function(v) {
					FlxG.drawFramerate = FlxG.updateFramerate = v;
				};
				opt;
			},
			{
				var opt = new Option("antialiasing", "antialiasing_desc", "antialiasing", BoolOption);
				opt.onChange = function(v) {
					for (i => cata in self.cateText.texts.members)
						cata.antialiasing = v;

					for (i => txt in self.optText.texts.members)
						txt.antialiasing = v;
					for (i => val in self.optText.subTexts.members)
						val.antialiasing = v;

					for (member in self.members) {
						if (!(member is flixel.FlxSprite)) continue;
						cast (member, flixel.FlxSprite).antialiasing = v;
					}
				}
				opt;
			},
			new Option("streams", "streams_desc", "audioStreams", BoolOption),
			new Option("reduced_quality", "reduced_quality_desc", "reducedQuality", BoolOption),
			{
				var opt = new Option("game_alpha", "game_alpha_desc", "gameVisibility", IntOption(0, 100, 5, false, true));
				opt.formatText = function(_) {
					return opt.value + "%";
				};
				opt;
			},
			new Option('videos', 'videos_desc', 'videos', BoolOption),
			new Option("reflections", "reflections_desc", "reflections", BoolOption),
			new Option("shaders", "shaders_desc", "shaders", BoolOption),
			new Option("hold_grain", "hold_grain_desc", "holdGrain", IntOption(1, 8, 1, false, true)),
			{
				var opt = new Option("gpu_cache", "gpu_cache_desc", "gpuCache", BoolOption);
				opt.onChange = function(v) {
					Controls.save();
					Settings.save();
					Sys.exit(1);
				}
				opt;
			}
		],
		"Misc." => [
			{
				var opt = new Option("fps_counter", "fps_counter_desc", 'infoCounter', BoolOption);
				opt.onChange = function(v) {
					Never2x.infoCounter.visible = v;
				};
				opt;
			},
			{
				var opt = new Option("fullscreen", "fullscreen_desc", "fullscreen", BoolOption);
				opt.onChange = function(v) {
					FlxG.fullscreen = v;
				};
				opt;
			}, 
			{
				var opt = new Option("discord_rpc", "discord_rpc_desc", "discordRPC", BoolOption);
				opt.onChange = function(_) DiscordClient.check();
				opt;
			},
			{
				var opt = new Option("auto_pause", "auto_pause_desc", "autoPause", BoolOption);
				opt.onChange = function(v) {
						FlxG.autoPause = v;
				};
				opt;
			},
			{
				var opt = new Option("calc_offset", "calc_offset_desc", "", ButtonOption);
				//opt.onChange = function(_) FlxG.switchState(new CalibrateOffsetState());
				opt;
			}
		]
	];
	public static var inPlayState:Bool = false;
	
	var lastList:TextList;
	var waitingForKey:Bool = false;
	var controllerMode:Bool = false;
	
	// applied on openCategory, basically optionsList[categoryList[selCategory]] with some filtering
	var curOptList:Array<Option> = [];
	var selCategory:Int = -1;

	var bg:FunkinSprite;
	var cateText:TextList;
	var optText:OptionList;

	var targetList(default, set):TextList;
	var targetPos:FlxPoint = FlxPoint.get();

	var noteEdit:NoteCustomization;
	var popupEdit:PopupTransform;

	override function create() {
		super.create();
		self = this;

		bg = new FunkinSprite(0, 0, Assets.image('images/menus/magentaBG'));
		bg.scale.scale(1.175);
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.wrapMode = REPEAT;
		add(bg);

		cateText = new TextList(10, 10, 300, 700, [for (cate in categoryList) _t(cate)]);
		cateText.onAccept = openCategory;
		cateText.onClick = openCategory;
		cateText.onSelect = function(_, __) {
			FlxG.sound.play(Assets.audio("sfx/scroll"));
		};

		optText = new OptionList(cateText.x + cateText.width + 10, cateText.y, FlxG.width - 330, 700);
		optText.onOptEnter = optEnter.bind(optText);

		noteEdit = new NoteCustomization(FlxG.width + 10, 10, FlxG.width - 20, FlxG.height - 20);
		noteEdit.onOptEnter = optEnter.bind(noteEdit);
		noteEdit.active = false;

		popupEdit = new PopupTransform(10, FlxG.height + 10, FlxG.width - 20, FlxG.height - 20);
		popupEdit.active = false;

		add(popupEdit); // dont want a chain reaction with onAccept
		add(noteEdit); 
		add(optText);
		add(cateText);

		openCategory(0);

		lastList = cateText;
		targetList = cateText;
	}

	override function update(delta:Float) {
		if (waitingForKey) {
			super.update(delta);

			final opt = curOptList[optText.current];
			inline function restore(sound:String) {
				optText.setSubText(optText.current, OptionList.getDesc(opt));
				optText.components[optText.current].change(opt);
				targetList = lastList;

				FlxG.sound.play(Assets.audio("sfx/" + sound));
				waitingForKey = false;
			}

			final binds:Array<Int> = cast opt.value;
			if (FlxG.keys.justPressed.ESCAPE) {
				restore("cancel");
				return;
			} else if (opt.curKey < binds.length && FlxG.keys.justPressed.DELETE) {
				binds.splice(opt.curKey, 1);
				opt.value = binds;
				restore("cancel");
				return;
			}

			var input = controllerMode ? (FlxG.gamepads.lastActive?.firstJustPressedID() ?? -1) : FlxG.keys.firstJustPressed();
			if (input != -1) {
				if (opt.curKey == binds.length)
					binds.push(input);
				else
					binds[opt.curKey] = input;

				opt.value = binds;

				restore("confirm");
			}
			return;
		} else if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			FlxG.sound.play(Assets.audio("sfx/cancel"));

			if (targetList == cateText) {
				if (inPlayState) FunkinState.switchState(new PlayState());
				else FunkinState.switchState(new MainMenuState());
			} else if (targetList == optText) {
				targetList = cateText;
			} else {
				targetList = lastList;
			}
		}
		super.update(delta);

		FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, targetPos.x, delta * 20);
		FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, targetPos.y, delta * 20);

		cateText.focused = cateText.allowKeys || cateText.hovered;
		optText.focused = optText.allowKeys || optText.hovered;
	}

	function optEnter(list:OptionList, current:Int) {
		switch (list.list[current].type) {
			case KeyOption:
				lastList = targetList;
				targetList.allowKeys = false;
				cateText.allowMouse = false;
				optText.allowMouse = false;
	
				waitingForKey = true;
				optText.setSubText(optText.current, _t("sel_key_desc"));
				cast (optText.components[optText.current], Textbox).text = "Setting...";
			case ListOption(options, true, translateItems):
				var opts:Array<String> = [for (value in options) list.list[current].formatListOption(value, translateItems == true)];
				var x:Float = FlxG.mouse.x;
				var y:Float = FlxG.mouse.y;
				if (Controls.justPressed("accept")) { // not by mouse
					@:privateAccess var hover = list.hover;
					x = hover.x + hover.scale.x;
					y = hover.y + hover.scale.y;
				}

				persistentUpdate = false;
				openSubState(new DropdownPrompt(x, y, 250, opts, function(idx) {
					FlxG.sound.play(Assets.audio("sfx/scroll"));
					list.list[current].value = options[idx];
					list.components[current].change(list.list[current]);
					@:privateAccess list.position(0);
				}));
			default: // nothin
		}
	}

	function openCategory(cate:Int) {
		FlxG.sound.play(Assets.audio("sfx/scroll"));
		if (targetList == optText && cate == selCategory)
			return;

		selCategory = cate;
		targetList = optText;

		curOptList.resize(0);
		final settingFields = Type.getInstanceFields(SaveVariables);
		for (opt in optionsList[categoryList[selCategory]]) {
			opt.controllerMode = controllerMode;
			if (opt.isValid(settingFields))
				curOptList.push(opt);
		}

		optText.setOptions(curOptList);
	}

	override function destroy() {
		super.destroy();
		Controls.save();
		Settings.save();
		Settings.updateNevermore();
		targetPos.put();
		self = null;
	}

	function set_targetList(to:TextList) {
		var mainOpts = to == cateText || to == optText;
		for (mem in members) {
			if (!Std.isOfType(mem, TextList))
				continue;
			var list:TextList = cast mem;
			var isMain:Bool = list == cateText || list == optText;

			list.allowKeys = list == to;
			list.allowMouse = (mainOpts && isMain) || list == to;
			list.active = isMain || list == to;
		}

		// damn switch didnt wanna work
		if (to == noteEdit)
			targetPos.set(FlxG.width, 0);
		else if (to == popupEdit)
			targetPos.set(0, FlxG.height);
		else
			targetPos.set();

		return targetList = to;
	}
}

class DropdownPrompt extends FlxSubState {
	var list:TextList;
	var twnVars:Dynamic;

	public function new(x:Float, y:Float, width:Float, options:Array<String>, onClick:Int->Void) {
		super();
		add(list = new TextList(x, y, width, 0, options));
		list.itemSpacing = 30;
		list.size = 18;
		list.height = Math.min(list.scrollInc * options.length, 600);
		list.scrollInc = Math.max(list.scrollInc * options.length - list.height, 0) / options.length;

		if (list.x + list.width >= FlxG.camera.scroll.x + FlxG.width - 10)
			list.x = FlxG.camera.scroll.x + FlxG.width - 10 - list.width;

		list.scale.y = 0;
		twnVars = {"scale.y": list.height};
		if (list.y + list.height >= FlxG.camera.scroll.y + FlxG.height - 10)
			twnVars.y = FlxG.camera.scroll.y + FlxG.height - 10 - list.height;

		FlxTween.tween(list, twnVars, 0.25, {ease: FlxEase.cubeOut});

		list.onAccept = list.onClick = function(current) {
			onClick(current);
			exit();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (Controls.justPressed("back") || FlxG.mouse.justPressedRight || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(list)))
			exit();
	}

	function exit() {
		this.parent.persistentUpdate = true;
		if (twnVars.y != null)
			twnVars.y = twnVars.y + list.height;
		Reflect.setField(twnVars, "scale.y", 0);
		FlxTween.tween(list, twnVars, 0.15, {ease: FlxEase.cubeOut, onComplete: function(twn) {
			close();
		}});
	}
}

enum OptionType {
	IntOption(min:Int, max:Int, ?inc:Int, ?wrap:Bool, ?slider:Bool);
	FloatOption(min:Float, max:Float, ?inc:Float, ?wrap:Bool, ?slider:Bool);
	BoolOption;
	ListOption(options:Array<String>, ?dropdown:Bool, ?translateItems:Bool);
	KeyOption;
	ButtonOption;
	Unselectable;
}

class Option {
	public var name:String;
	public var desc:String;
	public var sound:String = "scroll";

	public var id:String;
	public var type:OptionType;
	@:isVar public var value(get, set):Dynamic;

	//type specific
	public var powMult:Float = 1;
	public var curKey:Int = 0;
	public var controllerMode:Bool = false;

	public var hasEnter:Bool = false;
	public var hasMove:Bool = true;
	public var hasSound:Bool = true;
	public var textboxArrows:Bool = true;

	public dynamic function onChange(v:Dynamic) {}

	public dynamic function formatText(selected:Bool):String {
		return '$value';
	}

	public dynamic function formatListOption(item:String, translated:Bool) {
		if (translated)
			return _t(id + "_" + item);
		return item.toLowerCase() == "off" ? "OFF" : item;
	}

	public function new(name:String, desc:String, settingsVar:String, type:OptionType) {
		this.name = name;
		this.desc = desc;
		this.id = settingsVar;
		this.type = type;

		switch (type) {
			case BoolOption:
				hasEnter = true;
				formatText = function(_) {
					return _t(value ? "on" : "off").toUpperCase();
				};
			case KeyOption:
				hasEnter = true;
				sound = "scroll";
				formatText = function(selected) {
				    if(controllerMode) {
						final buttons:Array<FlxGamepadInputID> = cast value;
						return selected ? (curKey == buttons.length ? 'New Button' : '#${curKey + 1} (${formatGamepadButton(buttons[curKey])})') : [for (button in buttons) formatGamepadButton(button)].join(", ");
					}
					final keys:Array<FlxKey> = cast value;
					return selected ? (curKey == keys.length ? 'New Key' : '#${curKey + 1} (${formatKey(keys[curKey])})') : [for (key in keys) formatKey(key)].join(", ");
				};
			case ButtonOption | Unselectable:
				textboxArrows = false;
				hasMove = false;
				hasEnter = true;
				hasSound = false;
				formatText = function(_) {return "";};
			case ListOption(options, dropdown, translateItems):
				hasEnter = true;
				formatText = function(_) {return formatListOption(value, translateItems == true);};
			case FloatOption(min, max, inc, wrap, slider):
				// add some increment specific rounding to prevent .599999999999999999999
				inc ??= 0.05;
				// my desmos graph idea of 10 ^ floor(log(x)) did not work so now i need this
				while (inc < 1) {
					inc *= 10;
					powMult *= 10;
				}
				while (inc > 9) {
					inc *= 0.1;
					powMult *= 0.1;
				}
			default: // nothin
		}
	}

	public function enter() {
		switch (type) {
			case BoolOption:
				value = !value;
			case ButtonOption:
				onChange(null);
			default: // nothin
		}
	}

	public function change(left:Bool) {
		switch (type) {
			case IntOption(min, max, inc, wrap, slider):
				inc ??= 1;
				inc *= left ? -1 : 1;
				wrap ??= false;

				final range = (max - min);
				var curVal:Float = value;
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Std.int(curVal);
			case FloatOption(min, max, inc, wrap, slider):
				inc ??= 0.05;
				inc *= left ? -1 : 1;
				wrap ??= false;

				final range = (max - min);
				var curVal:Float = value;
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Math.round(curVal * powMult) / powMult;
			case BoolOption:
				value = !value;
			case ListOption(list, dropdown, translateItems):
				final inc = left ? -1 : 1;
				value = list[FlxMath.wrap(list.indexOf(value) + inc, 0, list.length - 1)];
			case KeyOption:
				final inc = left ? -1 : 1;
				final keys:Array<FlxKey> = cast value;
				curKey = (curKey + inc + keys.length + 1) % (keys.length + 1);

			case ButtonOption: onChange(null);
			default: // nothin
		}
	}

	public function isValid(settingFields:Array<String>) {
		return switch (type) {
			case ButtonOption | Unselectable: true;
			case KeyOption: controllerMode ? Controls.gamepad_binds.exists(id) : Controls.binds.exists(id);
			default: id != null && settingFields.contains(id);
		}
	}

	function get_value():Dynamic {
		if (type == KeyOption)
			return Controls.getBindSet(id, controllerMode);
		return Reflect.field(Settings.data, id);
	}

	function set_value(v:Dynamic):Dynamic {
		if (type == KeyOption)
			Controls.setBindSet(id, v, controllerMode);
		else
			Reflect.setField(Settings.data, id, v);

		onChange(v);
		return v;
	}

	public static function formatKey(key:FlxKey) {
		return switch (key) {
			case ZERO: "0";
			case ONE: "1";
			case TWO: "2";
			case THREE: "3";
			case FOUR: "4";
			case FIVE: "5";
			case SIX: "6";
			case SEVEN: "7";
			case EIGHT: "8";
			case NINE: "9";
			case PLUS: "+";
			case MINUS: "-";
			case NUMPADZERO: "KP-0";
			case NUMPADONE: "KP-1";
			case NUMPADTWO: "KP-2";
			case NUMPADTHREE: "KP-3";
			case NUMPADFOUR: "KP-4";
			case NUMPADFIVE: "KP-5";
			case NUMPADSIX: "KP-6";
			case NUMPADSEVEN: "KP-7";
			case NUMPADEIGHT: "KP-8";
			case NUMPADNINE: "KP-9";
			case NUMPADPLUS: "KP-+";
			case NUMPADMINUS: "KP--";
			case PAGEUP: "PG-UP";
			case PAGEDOWN: "PG-DOWN";
			case DELETE: "DEL";
			case ESCAPE: "ESC";
			case BACKSPACE: "BKSP";
			case LBRACKET: "[";
			case RBRACKET: "]";
			case BACKSLASH: "\\";
			case CAPSLOCK: "CAPS";
			default: key.toString();
		}
	}

	public static function formatGamepadButton(button:FlxGamepadInputID) {
        final gamepad:FlxGamepad = FlxG.gamepads.firstActive;
        final model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
	    switch(button) {
			// Analogs
			case LEFT_STICK_DIGITAL_LEFT:
				return "Left";

			case LEFT_STICK_DIGITAL_RIGHT:
				return "Right";

			case LEFT_STICK_DIGITAL_UP:
				return "Up";

			case LEFT_STICK_DIGITAL_DOWN:
				return "Down";

			case LEFT_STICK_CLICK:
				switch (model) {
					case PS4: return "L3";
					case XINPUT: return "LS";
					default: return "Analog Click";
				}

			case RIGHT_STICK_DIGITAL_LEFT:
				return "C. Left";

			case RIGHT_STICK_DIGITAL_RIGHT:
				return "C. Right";

			case RIGHT_STICK_DIGITAL_UP:
				return "C. Up";

			case RIGHT_STICK_DIGITAL_DOWN:
				return "C. Down";

			case RIGHT_STICK_CLICK:
				switch (model) {
					case PS4: return "R3";
					case XINPUT: return "RS";
					default: return "C. Click";
				}

			// Directional
			case DPAD_LEFT:
				return "D. Left";
			case DPAD_RIGHT:
				return "D. Right";
			case DPAD_UP:
				return "D. Up";
			case DPAD_DOWN:
				return "D. Down";

			// Top buttons
			case LEFT_SHOULDER:
				switch(model) {
					case PS4: return "L1";
					case XINPUT: return "LB";
					default: return "L. Bumper";
				}

			case RIGHT_SHOULDER:
				switch(model) {
					case PS4: return "R1";
					case XINPUT: return "RB";
					default: return "R. Bumper";
				}

			case LEFT_TRIGGER, LEFT_TRIGGER_BUTTON:
				switch(model) {
					case PS4: return "L2";
					case XINPUT: return "LT";
					default: return "L. Trigger";
				}

			case RIGHT_TRIGGER, RIGHT_TRIGGER_BUTTON:
				switch(model) {
					case PS4: return "R2";
					case XINPUT: return "RT";
					default: return "R. Trigger";
				}

			// Buttons
			case A:
				switch (model) {
					case PS4: return "X";
					case XINPUT: return "A";
					default: return "Action Down";
				}
			case B:
				switch (model) {
					case PS4: return "O";
					case XINPUT: return "B";
					default: return "Action Right";
				}
			case X:
				switch (model) {
					case PS4: return "ロ";
					case XINPUT: return "X";
					default: return "Action Left";
				}
			case Y:
				switch (model) {
					case PS4: return "Δ";
					case XINPUT: return "Y";
					default: return "Action Up";
				}

			case BACK:
				switch(model) {
					case PS4: return "Share";
					case XINPUT: return "Back";
					default: return "Select";
				}
			case START:
				switch(model) {
					case PS4: return "Options";
					default: return "Start";
				}

			case NONE:
				return '---';

			default: return button.toString();
		}
	}
}