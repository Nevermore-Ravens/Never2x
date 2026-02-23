package funkin.states;

import haxe.io.Path;
import funkin.objects.Note;
import funkin.objects.NoteSplash;
import funkin.objects.FunkinSprite;
import funkin.objects.PlayField;
import funkin.objects.Strumline;
import funkin.backend.Settings.SaveVariables;
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
					FlxG.sound.muteKeys = v;
				}
				opt;
			},
			{
				var opt = new Option("volume_up", "volume_up_desc", "volume_up", KeyOption);
				opt.onChange = function(v) {
					// reverse the function before settings as this gets inputted after setting.
					FlxG.sound.changeVolume(-0.1);
					FlxG.sound.volumeUpKeys = v;
				}
				opt;
			},
			{
				var opt = new Option("volume_down", "volume_down_desc", "volume_down", KeyOption);
				opt.onChange = function(v) {
					// reverse the function before settings as this gets inputted after setting.
					FlxG.sound.changeVolume(0.1);
					FlxG.sound.volumeDownKeys = v;
				}
				opt;
			}
			// ill not add the debug keys
		],
		"Gameplay" => [
			{
				var opt = new Option('scroll_dir', 'scroll_dir_desc', "scrollDirection", ListOption(["Up", "Down"]));
				opt.onChange = function(val) {
					var endPercent = val == "Down" ? 1 : 0;
					var percent = 1.0 - endPercent;
					var time = 0.5;
					if (self.scrollTwn != null && !self.scrollTwn.finished) {
						@:privateAccess time = self.scrollTwn._secondsSinceStart;
						percent = Math.abs(endPercent - self.scrollTwn.scale);
						self.scrollTwn.cancel();
					}
					self.scrollTwn = FlxTween.num(percent, endPercent, time, {ease: FlxEase.cubeInOut}, function(num) {
						self.playfield.downscroll = num >= 0.5;
						self.strumline.overrideScrollSpeed = Math.abs(num - endPercent) <= 0.01 ? 0 : Math.max(self.playfield.scrollSpeed * Math.abs(num - 0.5) * 2, 0.001);
						self.strumline.y = FlxMath.lerp(50, FlxG.height - 50 - Strumline.swagWidth, num);
						//self.text.y = FlxMath.lerp(600, 50, num);
					});
				};
				opt;
			},
			{
				var opt = new Option('scroll_speed', 'scroll_speed_desc', "scrollSpeed", FloatOption(0.5, 7, 0.05));
				opt.onChange = function(val) {
					FlxTween.tween(self.playfield, {scrollSpeed: val}, 0.25, {ease: FlxEase.cubeOut});
				};
				opt;
			},
			{
				final possible: Array<String> = [];
				final names: Map<String, String> = [];
				for (path in Paths.readDirectory("data/noteSkins"))
					if (path.endsWith(".json5") || path.endsWith(".json")) {
						var name:String = Path.withoutDirectory(Path.withoutExtension(path));
						if(name == "default" || possible.contains(name)) continue;
						var data = funkin.backend.NoteSkin.get(name);
						possible.push(name);
						names.set(name, data.displayName);
					}
	
				var opt = new Option("note_skin", "note_skin_desc", "noteSkin", ListOption(possible));
				opt.onChange = function(val) {
					self.strumline.skin = val;
					@:privateAccess for (note in self.playfield.notes.members) {
						if (note.exists)
							note.skin = val;
					}
				}
				opt.formatText = function(_) {
					return names[opt.value];
				};
				opt;
			},
			{
				final possibleNotesplashes: Array<String> = ['none'];
				final notesplashNames: Map<String, String> = ['none' => 'None'];
				for (splashPath in Paths.readDirectory("data/noteSplashes"))
					if (splashPath.endsWith(".json5") || splashPath.endsWith(".json")) {
						var splashName:String = Path.withoutDirectory(Path.withoutExtension(splashPath));
						if(possibleNotesplashes.contains(splashName)) continue;
						var data = NoteSplashData.get(splashName);
						possibleNotesplashes.insert(0, splashName);
						notesplashNames.set(splashName, data.name);
					}

				var opt = new Option("splash_skin", "splash_skin_desc", "noteSplashSkin", ListOption(possibleNotesplashes));
				opt.onChange = function(val) {
					self.strumline.style = val;
					@:privateAccess for (note in self.playfield.notes.members) {
						if (note.exists)
							note.style = val;
					}
				}
				opt.formatText = function(_) {
					return notesplashNames.get(opt.value) ?? 'Fallback (${opt.value})'; // Display the name so you can figure out what the splash WAS
				};
				opt;
			},
			{ // this can be reverted if the order of the quants matter
				var quantPalettes: Array<String> = [];
				for(name in funkin.objects.Note.quantPalettes.keys())
					quantPalettes.push(name);

				quantPalettes.unshift('None');

				var opt = new Option('quant_col', 'quant_col_desc', "quantColouring", ListOption(quantPalettes));
				opt;
			},
			{
				var opt = new Option('note_offset', 'note_offset_desc', "noteOffset", FloatOption(-5000, 5000, 1));
				opt.formatText = function(_) {
					return opt.value + " MS";
				};
				opt;
			},
			new Option('ghost_t', 'ghost_t_desc', "ghostTapping", BoolOption),
			new Option('metronome', 'metronome_desc', "metronome", BoolOption),
			new Option('assist_claps', 'assist_claps_desc', "assistClaps", BoolOption),
			new Option('can_reset', 'can_reset_desc', "canReset", BoolOption),
			//new Option('acc_type', 'acc_type_desc', "accuracyType", ListOption(["Simple", "Complex"]))
			//i'm gonna be honest, all complex acc does is make ranking inconsistent, given how we have
			//standardized score based on judgements now i really don't see a need to have complex acc at all -fox
		],
		"HUD" => [
			new Option("judge_counter", "judge_counter_desc", "judgementCounter", BoolOption),
			new Option('hit_error_bar', 'hit_error_bar_desc', "hitErrorBar", BoolOption),
			new Option("combo_tinting", "combo_tinting_desc", "comboTinting", ListOption(["Off", "Clear Flag", "Per-Note"])),
			new Option("popup_cent", "popup_cent_desc", "popupCenter", ListOption(["FNF", "Field", "Center"])),
			new Option("hide_acc", "hide_acc_desc", "hideAcc", BoolOption),
			new Option("hide_hud", "hide_hud_desc", "hideHUD", BoolOption),
			{
				var opt = new Option("judge_alpha", "judge_alpha_desc", "judgementAlpha", FloatOption(0, 1, 0.05));
					opt.formatText = function(_) {
						return (opt.value * 100) + "%";
					};
					opt;
			},
			{
				var opt = new Option("combo_alpha", "combo_alpha_desc", "comboAlpha", FloatOption(0, 1, 0.05));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			},
			{
				var opt = new Option("hp_alpha", "hp_alpha_desc", "healthBarAlpha", FloatOption(0, 1, 0.05));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			}
		],
		"Visuals" => [
			{
				var opt = new Option('language', 'language_desc', "language", ListOption(LanguageHandler.getLanguages()));
				opt.onChange = function(v) {
					LanguageHandler.setLanguage(v);
					for (i => cata in self.listGrp.members)
						cata.text = _t(self.categoryList[i]).toUpperCase();

					for (i => txt in self.optTxt.members) {
						final opt = self.curOptList[i];
						txt.text = (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name)).toUpperCase();
						self.optValTxt.members[i].text = opt.formatText(i == self.curSelected);
					}

					self.lastDescHeight = self.descBG.scale.y;
					self.descTxt.text = self.getDesc(self.curOptList[self.curSelected]);
				}
				opt;
			},
			new Option("flashing_lights", "flashing_lights_desc", "flashingLights", BoolOption),
			{
				var opt = new Option('strum_size', 'strum_size_desc', 'strumSize', FloatOption(0.05, 3, 0.05, false));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt.onChange = function(val) {
					if (self.sizeTwn != null && !self.sizeTwn.finished)
						self.sizeTwn.cancel();

					self.sizeTwn = FlxTween.num(Strumline.size, val, 0.5, {ease: FlxEase.quadOut}, function(num) {
						Strumline.size = num;
						if (self.playfield.downscroll)
							self.strumline.y = FlxG.height - 50 - Strumline.swagWidth;

						for (i => strum in self.strumline.members) {
							final skinScale = self.strumline.styleData.getScale(strum);
							strum.scale.set(skinScale * num, skinScale * num);
							strum.updateHitbox();
							strum.setPosition(
								self.strumline.x + Strumline.swagWidth * i,
								self.strumline.y + (Strumline.swagWidth - strum.height) * 0.5
							);
						}
						@:privateAccess for (note in self.playfield.notes.members) {
							if (!note.exists) continue;
							final skinScale = note.styleData.getScale(note);
							note.scale.set(skinScale * num, skinScale * num);
							note.updateHitbox();
						}
						self.strumline.x = (FlxG.width - self.strumline.width) * 0.5 + 400;
					});
				};
				opt;
			},
			new Option('center_notes', 'center_notes_desc', "centeredNotes", BoolOption),
			new Option('opp_notes', 'opp_notes_desc', "opponentNotes", BoolOption),
			//and this is where i would put lane underlay ^_^...........IF I HAD ONE!!
			new Option("cam_zooms", "cam_zooms_desc", "cameraZooms", ListOption(["Default", "Off"])),
			new Option("cam_movement", "cam_movement_desc", "notesMoveCamera", BoolOption),
			new Option('strum_glow', 'strum_glow_desc', 'strumGlow', ListOption(['Off', 'Judgement', 'Per-Note'])),
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
					for (i => cata in self.listGrp.members)
						cata.antialiasing = v;

					for (i => txt in self.optTxt.members)
						txt.antialiasing = v;
					for (i => val in self.optValTxt.members)
						val.antialiasing = v;

					for (member in self.members) {
						if (!(member is flixel.FlxSprite)) continue;
						cast (member, flixel.FlxSprite).antialiasing = v;
					}
				}
				opt;
			},
			new Option("streams", "streams_desc", "audioStreams", BoolOption),
			{
				var opt = new Option("reduced_quality", "reduced_quality", "reducedQuality", BoolOption);
				opt.onChange = function(v) {
					//self.lineBG.shader = v ? null : self.lineShader;
				}
				opt;
			},
			{
				var opt = new Option("game_alpha", "game_alpha_desc", "gameVisibility", IntOption(0, 100, 5));
				opt.formatText = function(_) {
						return opt.value + "%";
				};
				opt;
			},
			new Option('videos', 'videos_desc', 'videos', BoolOption),
			new Option("reflections", "reflections_desc", "reflections", BoolOption),
			new Option("shaders", "shaders_desc", "shaders", BoolOption),
			new Option("hold_grain", "hold_grain_desc", "holdGrain", IntOption(1, 8, 1)),
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
				var opt = new Option("fps_counter", "fps_counter_desc", 'fpsCounter', BoolOption);
				opt.onChange = function(v) {
						Main.fpsCounter.visible = v;
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
				opt.onChange = function(_) {
					self.playfield.botplay = false;
					self.totalNoteDifference = 0;
					self.notesHit = 0;
					self.finalOffset = Settings.data.noteOffset;

					self.selOptScale = 0;
					self.descTxt.text = _formatT("offset_cali_result", [Std.string(self.finalOffset), self.finalOffset > 0 ? _t("late") : _t("early")]);
					self.descTxt.alignment = CENTER;
					self.lastDescHeight = self.descBG.scale.y;
				};
				opt;
			}
		]
	];

	public static var inPlayState:Bool = false;
	var selCategory:Int = -1;
	var curCategory:Int = 0;
	var curSelected:Int = 0;

	// variables to create a mouse deadzone
	final MOUSE_DEADZONE = 5; // technically 10, but goes in both directions.
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	public var mouseMoved:Bool = false;

	// 0 - None, 1 - Left, 2 - Right, 3 - Mouse Left, 4 - Mouse Right
	var curHolding:Int = 0;
	var holdWait:Float = 0.5;

	var keysInOpts:Bool = false;
	var waitingForKey:Bool = false;
	var controllerMode:Bool = false;

	// applied on openCategory, basically optionsList[categoryList[selCategory]] with some filtering
	var curOptList:Array<Option> = [];

	var scrollTime:Float = 0;
	var bg:FunkinSprite;
	var listBG:FunkinSprite;
	var listGrp:FlxTypedGroup<FlxText>;

	var curOptScroll:Float = 0;
	var optScrollInc:Float = 0;
	var selOptScale:Float = 0;
	var optBG:FunkinSprite;
	var optTxt:FlxTypedGroup<FlxText>;
	var optValTxt:FlxTypedGroup<FlxText>;

	var lastDescHeight:Float = 0;
	var descBG:FunkinSprite;
	var descTxt:FlxText;

	// Calibration Stuff
	var nextNote:Note;
	var playfield:PlayField;
	var strumline:Strumline;
	var musicBeatLen:Float = 2;
	var aboutToLoop:Bool = false;
	var totalNoteDifference:Float = 0;
	var notesHit:Int = 0;
	var finalOffset:Float = 0;
	var scrollTwn:FlxTween;
	var sizeTwn:FlxTween;

	override function create() {
		super.create();
		self = this;
		musicBeatLen = Conductor.inst.length / Conductor.crotchet;

		bg = new FunkinSprite().loadGraphic(Paths.image('menus/magentaBG'));
		bg.scale.scale(1.175);
		bg.updateHitbox();
		bg.screenCenter();
		bg.wrapMode = REPEAT;
		add(bg);

		initCalibrationField();

		add(listBG = new FunkinSprite(10, 10).makeGraphic(1, 1, 0x70000000));
		listBG.setGraphicSize(300, 700);
		listBG.updateHitbox();

		add(listGrp = new FlxTypedGroup<FlxText>());
		var y = listBG.y + 15;
		for (i => cate in categoryList) {
			var txt = new FlxText(listBG.x + 15, y, listBG.width - 30, _t(cate));
			txt.setFormat(Paths.font("cafeSquare.ttf"), 24, i != curSelected ?0xFF90A0A0 : 0xFFFFFFFF);
			txt.antialiasing = Settings.data.antialiasing;
			listGrp.add(txt);
			y += 30;
		}

		add(optBG = new FunkinSprite(listBG.x + listBG.width + 10, listBG.y).makeGraphic(1, 1, 0x70000000));
		optBG.scale.set(500, 700);
		optBG.updateHitbox();

		add(optValTxt = new FlxTypedGroup<FlxText>());
		add(optTxt = new FlxTypedGroup<FlxText>());

		add(descBG = new FunkinSprite(optBG.x + optBG.width + 10, 0).makeGraphic(1, 1, 0x70000000));
		descBG.scale.set(FlxG.width - descBG.x - 10, 120);
		descBG.updateHitbox();
		descBG.scale.y = 0;
		descBG.offset.set();
		descBG.origin.set();

		add(descTxt = new FlxText(descBG.x + 10, descBG.y + 10, descBG.width - 20, ""));
		descTxt.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFFFFF, LEFT);

		openCategory(curCategory);
		keysInOpts = false;
	}

	override function update(delta:Float) {
		super.update(delta);

		scrollTime += delta * 25;
		bg.clipGraphic(scrollTime, 0, bg.frameWidth, bg.frameHeight);

        mouseMoved = false;
		if (Math.abs(FlxG.mouse.screenX - lastMouseX) >= MOUSE_DEADZONE || Math.abs(FlxG.mouse.screenY - lastMouseY) >= MOUSE_DEADZONE) {
			lastMouseX = FlxG.mouse.screenX;
			lastMouseY = FlxG.mouse.screenY;
			mouseMoved = true;
		}

		// Calibration looping
		final time = Conductor.rawTime - Conductor.offset;
		if (aboutToLoop && time <= Conductor.crotchet * 2) {
			aboutToLoop = false;
			trace("looped!");
			Conductor.offset += Math.ceil(musicBeatLen * 0.5) * 2 * Conductor.crotchet; // snap it to the next even beat
		}
		aboutToLoop = time >= Conductor.crotchet * (musicBeatLen - 2);

		var listAlpha = 0.3;
		var optAlpha = 0.3;
		if (waitingForKey) {
			optAlpha = 1;
			final opt = curOptList[curSelected];
			final keys:Array<FlxKey> = cast opt.value;
			if (FlxG.keys.justPressed.ESCAPE) {
				waitingForKey = false;
				FlxG.sound.play(Paths.audio("cancel", 'sfx'));

				optValTxt.members[curSelected].text = opt.formatText(true);
				descTxt.text = getDesc(curOptList[curSelected]);
				return;
			} else if (opt.curKey < keys.length && FlxG.keys.justPressed.DELETE) {
				waitingForKey = false;
				FlxG.sound.play(Paths.audio("cancel", 'sfx'));
				
				keys.splice(opt.curKey, 1);
				opt.value = keys;

				optValTxt.members[curSelected].text = opt.formatText(true);
				descTxt.text = getDesc(curOptList[curSelected]);
				return;
			}

			var input = controllerMode ? (FlxG.gamepads.lastActive?.firstJustPressedID() ?? -1) : FlxG.keys.firstJustPressed();
			if (input != -1) {
				final binds:Array<Int> = cast opt.value;
				waitingForKey = false;

				if (opt.curKey == binds.length)
					binds.push(input);
				else
					binds[opt.curKey] = input;

				opt.value = binds;

				optValTxt.members[curSelected].text = opt.formatText(true);
				descTxt.text = getDesc(opt);
				FlxG.sound.play(Paths.audio("confirm", "sfx"));
			}
		} else if (playfield.botplay) {
			if (mouseOpts() || keysInOpts)
				optAlpha = 1;
			if (mouseCategories() || !keysInOpts)
				listAlpha = 1;

			(keysInOpts ? optInputs : cateInputs)(delta);
		} else {
			final acceptJustPressed = Controls.justPressed("accept");
			if (acceptJustPressed || Controls.justPressed("back") || FlxG.mouse.justPressedRight) {
				if (acceptJustPressed) {
					Settings.data.noteOffset = finalOffset;
					FlxG.sound.play(Paths.audio("scroll", "sfx"));
				} else
					FlxG.sound.play(Paths.audio("cancel", "sfx"));
				playfield.botplay = true;
				selOptScale = 0;
				descTxt.text = getDesc(curOptList[curSelected]);
				self.descTxt.alignment = LEFT;
				lastDescHeight = descBG.scale.y;
			}
		}
		listBG.alpha = FlxMath.lerp(listBG.alpha, listAlpha, delta * 15);
		optBG.alpha = FlxMath.lerp(optBG.alpha, optAlpha, delta * 15);
		strumline.alpha = FlxMath.lerp(strumline.alpha, (playfield.botplay ? 0.3 : 1), delta * 15);

		for (item in listGrp.members)
			item.alpha = listBG.alpha;
		for (item in optTxt.members)
			item.alpha = optBG.alpha;
		for (item in optValTxt.members)
			item.alpha = optBG.alpha;

		curOptScroll = FlxMath.lerp(curOptScroll, optScrollInc * curSelected, delta * 15);
		/*final topMargin = optBG.y;
		final botMargin = (optBG.y + optBG.frameHeight * optBG.scale.y);
		Util.reposNClipTexts(optTxt, curSelected, topMargin, botMargin, (optBG.y + 25 - curOptScroll), delta, function(idx:Int, y:Float, scale:Float) {
			// similar code to the static func just for val.
			final txt = optTxt.members[idx];
			final val = optValTxt.members[idx];
			@:privateAccess val.regenGraphic();

			val.origin.x = val.frameWidth;
			val.scale.copyFrom(txt.scale);

			val.x = optBG.x + optBG.width - 20 - val.width;
			val.y = txt.y + (txt.height - val.height) * 0.5 + ((idx == curSelected) ? 3 * scale : 0);

			final tMargin = (idx == curSelected) ? Math.max(optSel.y + (optSel.height - optSel.scale.y) * 0.5, topMargin) : topMargin;
			final bMargin = (idx == curSelected) ? Math.min(optSel.y + (optSel.height + optSel.scale.y) * 0.5, botMargin) : botMargin;
			Util.clipByCoords(val, optSel.x, null, tMargin, bMargin);
		});*/

		selOptScale = Math.min(Math.max(selOptScale + delta * 4, 0.0), 1.0);
		descBG.scale.y = FlxMath.lerp(lastDescHeight, descTxt.height + 30, FlxEase.backOut(selOptScale));
		Util.clipByCoords(descTxt, null, null, null, descBG.y + descBG.scale.y);

		var targetDescY = Math.min(optTxt.members[curSelected].y - 15, FlxG.height - 10 - (descTxt.height + 30));
		descBG.y = FlxMath.lerp(descBG.y, ((playfield.botplay && !waitingForKey) ? targetDescY : (FlxG.height - descTxt.height) * 0.5 - 15), delta * 20);
		descTxt.y = descBG.y + 15;
	}

	function initCalibrationField() {
		strumline = new Strumline(0, 0, true);
		strumline.screenCenter(X);
		strumline.x += 400;
		strumline.alpha = 0.3;
		strumline.directAlpha = true;

		add(playfield = new PlayField([strumline]));
		playfield.downscroll = Settings.data.downscroll;
		playfield.scrollSpeed = Settings.data.scrollSpeed;
		playfield.playAssistClaps = false;
		playfield.botplay = true;
		playfield.playerID = 0;
		playfield.noteHit = noteHit;
		playfield.noteMiss = recoverNote;
		strumline.y = playfield.downscroll ? FlxG.height - 50 - Strumline.swagWidth : 50;

		playfield.load([
			{time: Conductor.crotchet * Math.ceil(Conductor.floatBeat * 0.5) * 2, lane: 0, type: ""},
			{time: Conductor.crotchet * (Math.ceil(Conductor.floatBeat * 0.5) * 2 + 2), lane: 3, type: ""}
		]);
		nextNote = new Note();
		nextNote.kill();
		@:privateAccess playfield.notes.add(nextNote);
	}

	function openCategory(cate:Int) {
		FlxG.sound.play(Paths.audio("scroll", 'sfx'));
		if (cate == selCategory)
			return;

		selCategory = cate;
		keysInOpts = true;

		while (optTxt.length > 0) {
			final txt = optTxt.members[0];
			final val = optValTxt.members[0];
			optTxt.remove(txt, true);
			optValTxt.remove(val, true);
			txt.destroy();
			val.destroy();
		}

		curOptList.resize(0);
		final settingFields = Type.getInstanceFields(SaveVariables);
		for (opt in optionsList[categoryList[selCategory]]) {
			opt.controllerMode = controllerMode;
			if (opt.isValid(settingFields))
				curOptList.push(opt);
		}

		curSelected = 0;
		var y = optBG.y + 15;
		for (i => opt in curOptList) {
			var txt = new FlxText(optBG.x + 15, y, optBG.width - 30, (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name)));
			var val = new FlxText(txt.x, txt.y, optBG.width - 30, opt.formatText(i == curSelected));
			txt.setFormat(Paths.font("cafeSquare.ttf"), 24, (i != curSelected ?0xFF90A0A0 : 0xFFFFFFFF), LEFT);
			val.setFormat(Paths.font("vcr.ttf"), 24, (i != curSelected ?0xFF90A0A0 : 0xFFFFFFFF), RIGHT);
			txt.antialiasing = Settings.data.antialiasing;
			val.antialiasing = Settings.data.antialiasing;
			optTxt.add(txt);
			optValTxt.add(val);
			y += 30;
		}
		optScrollInc = Math.max(curOptList.length * 35 + 60 - optBG.frameHeight, 0) / curOptList.length;

		selOptScale = 0;
		descTxt.text = getDesc(curOptList[curSelected]);
		lastDescHeight = descBG.scale.y;
	}

	function retargetCate(target:Int) {
		if (target == curCategory) return;

		listGrp.members[curCategory].color = 0xFF90A0A0;

		curCategory = target;

		listGrp.members[curCategory].color = -1;

		FlxG.sound.play(Paths.audio("scroll", 'sfx'));
	}

	function mouseCategories() {
		if (FlxG.mouse.screenX < listBG.x || FlxG.mouse.screenX > listBG.x + listBG.width)
			return false;

		for (i in 0...listGrp.length) {
			var top = listBG.y + 15 + 30 * i;

			if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + 30) {
				retargetCate(mouseMoved ? i : curCategory);

				if (FlxG.mouse.justPressed)
					openCategory(i);
				break;
			}
		}
		return true;
	}

	function cateInputs(delta:Float) {
		final downJustPressed = Controls.justPressed("ui_down");
		if (downJustPressed || Controls.justPressed("ui_up"))
			retargetCate(FlxMath.wrap(curCategory + (downJustPressed ? 1 : -1), 0, categoryList.length - 1));

		if (Controls.justPressed('accept')) {
			openCategory(curCategory);
		} else if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			descTxt.text = "";
			FlxG.sound.play(Paths.audio("cancel", 'sfx'));

			//Border.transitionTween(true, false, border, 0.25, 0.25, function() {
				if (inPlayState) FlxG.switchState(new PlayState());
				else FlxG.switchState(new MainMenuState());
			//});
		}
	}

	function getDesc(opt:Option) {
		return (opt.desc.startsWith("<NO-LANG>") ? opt.desc.substring(9, opt.desc.length) : _formatT(opt.desc, [_t("accept").toUpperCase()])) + (opt.type == KeyOption ? "\n\n" + _formatT("key_opt_desc", [_t("accept").toUpperCase()]) : "");
	}

	function retargetOpt(target:Int) {
		if (target == curSelected) return;

		optTxt.members[curSelected].color = 0xFF90A0A0;
		optValTxt.members[curSelected].color = 0xFF90A0A0;
		optValTxt.members[curSelected].text = curOptList[curSelected].formatText(false);

		curSelected = target;
		selOptScale = 0;

		optTxt.members[curSelected].color = -1;
		optValTxt.members[curSelected].color = -1;
		optValTxt.members[curSelected].text = curOptList[curSelected].formatText(true);

		descTxt.text = getDesc(curOptList[curSelected]);
		lastDescHeight = descBG.scale.y;

		FlxG.sound.play(Paths.audio("scroll", 'sfx'));
	}

	function mouseOpts() {
		if (FlxG.mouse.screenX < optBG.x || FlxG.mouse.screenX > optBG.x + optBG.width)
			return false;

		for (i in 0...optTxt.length) {
			var top = listBG.y + 15 + 30 * i;
			if (FlxG.mouse.y >= top && FlxG.mouse.y <= top + 30 && curOptList[i].type != Unselectable) {
				retargetOpt(mouseMoved ? i : curSelected);
				if (FlxG.mouse.justPressed) {
					if (curOptList[curSelected].type == ButtonOption) {
						curOptList[curSelected].change(false);
					} else if (curOptList[curSelected].type == BoolOption) {
						curOptList[curSelected].change(false);
						FlxG.sound.play(Paths.audio(curOptList[curSelected].sound, 'sfx'));
						optValTxt.members[curSelected].text = curOptList[curSelected].formatText(true);
					} else if (curOptList[curSelected].type == KeyOption) {
						waitingForKey = true;
						descTxt.text = _formatT("sel_key_desc", [","]);
						optValTxt.members[curSelected].text = "Setting...";
						FlxG.sound.play(Paths.audio("scroll", "sfx"));
					} else if (Math.abs(FlxG.mouse.screenX - (optBG.x + optBG.width * 0.5)) >= optBG.width * 0.5 - 25) {
						final isLeft = FlxG.mouse.screenX <= optBG.x + 25;
						curHolding = isLeft ? 3 : 4;
						holdWait = 0.5;

						curOptList[curSelected].change(isLeft);
						FlxG.sound.play(Paths.audio(curOptList[curSelected].sound, 'sfx'));
						optValTxt.members[curSelected].text = curOptList[curSelected].formatText(true);
					}
				}
				break;
			}
		}
		return true;
	}

	function optInputs(delta:Float) {
		final downJustPressed:Bool = Controls.justPressed('ui_down');
		final leftJustPressed:Bool = Controls.justPressed('ui_left');

		if (downJustPressed || Controls.justPressed('ui_up')) {
			final firstNew = FlxMath.wrap(curSelected + (downJustPressed ? 1 : -1), 0, curOptList.length - 1);
			var newOpt = firstNew;
			while (curOptList[newOpt].type == Unselectable) {
				newOpt = FlxMath.wrap(newOpt + (downJustPressed ? 1 : -1), 0, curOptList.length - 1);
				if (newOpt == firstNew)
					break; // safety
			}
			retargetOpt(newOpt);
		}

		final curOption = curOptList[curSelected];
		if ((leftJustPressed || Controls.justPressed('ui_right'))) {
			curHolding = leftJustPressed ? 1 : 2;
			holdWait = 0.5;

			curOption.change(leftJustPressed);
			FlxG.sound.play(Paths.audio(curOption.sound, 'sfx'));
			optValTxt.members[curSelected].text = curOption.formatText(true);
		}
		
		curHolding = switch (curHolding) {
			case 1: Controls.pressed("ui_left") ? 1 : 0;
			case 2: Controls.pressed("ui_right") ? 2 : 0;
			case 3 | 4: FlxG.mouse.pressed ? curHolding : 0;
			default: 0;
		};
		if (curHolding != 0) {
			holdWait -= delta;
			if (holdWait <= 0) {
				holdWait = 0.035; // make the changing more consistent
				curOption.change(curHolding % 2 == 1);
				optValTxt.members[curSelected].text = curOption.formatText(true);
			}
		}
		
		if (Controls.justPressed("accept")) {
			if (curOption.type == BoolOption) {
				curOption.change(false);
				FlxG.sound.play(Paths.audio(curOption.sound, 'sfx'));
				optValTxt.members[curSelected].text = curOption.formatText(true);
			} else if (curOption.type == KeyOption) {
				waitingForKey = true;
				descTxt.text = _formatT("sel_key_desc", [","]);
				optValTxt.members[curSelected].text = "Setting...";
				FlxG.sound.play(Paths.audio("scroll", "sfx"));
			} else if (curOption.type == ButtonOption) curOption.change(false);
		}

		if (Controls.justPressed("back") || FlxG.mouse.justPressedRight) {
			keysInOpts = false;
			FlxG.sound.play(Paths.audio("cancel", 'sfx'));
		}
	}

	function recoverNote(_, note:Note):Void {
		note.data.time += Conductor.crotchet * 4;
		nextNote.revive();
		nextNote.setup(note.data);
		nextNote = note;
	}
	function noteHit(_, note:Note):Void {
		if (playfield.botplay) {
			recoverNote(_, note);
			return;
		}

		totalNoteDifference += note.hitTime;
		notesHit++;

		finalOffset = Math.round(totalNoteDifference / notesHit) + Settings.data.noteOffset; // don't want the base offset screwing this up.
		descTxt.text = _formatT("offset_cali_result", [Std.string(finalOffset), finalOffset > 0 ? _t("late") : _t("early")]);
		recoverNote(_, note);
	}

	override function destroy() {
		super.destroy();
		Controls.save();
		Settings.save();
		if (sizeTwn != null && !sizeTwn.finished)
			sizeTwn.cancel();
		Strumline.size = Settings.data.strumSize;
		self = null;
	}
}

enum OptionType {
	IntOption(min:Int, max:Int, ?inc:Int, ?wrap:Bool);
	FloatOption(min:Float, max:Float, ?inc:Float, ?wrap:Bool);
	BoolOption;
	ListOption(options:Array<String>, ?translateItems:Bool);
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

	public dynamic function onChange(v:Dynamic) {}

	public dynamic function formatText(selected:Bool):String {
		return '$value';
	}

	public function new(name:String, desc:String, settingsVar:String, type:OptionType) {
		this.name = name;
		this.desc = desc;
		this.id = settingsVar;
		this.type = type;

		switch (type) {
			case BoolOption:
				formatText = function(_) {
					return _t(value ? "on" : "off").toUpperCase();
				};
			case KeyOption:
				formatText = function(selected) {
				    if(controllerMode) {
						final buttons:Array<FlxGamepadInputID> = cast value;
						return selected ? (curKey == buttons.length ? 'New Button' : '#${curKey + 1} (${formatGamepadButton(buttons[curKey])})') : [for (button in buttons) formatGamepadButton(button)].join(", ");
					}
					final keys:Array<FlxKey> = cast value;
					return selected ? (curKey == keys.length ? 'New Key' : '#${curKey + 1} (${formatKey(keys[curKey])})') : [for (key in keys) formatKey(key)].join(", ");
				};
			case ButtonOption | Unselectable:
				formatText = function(_) {return "";};
			case ListOption(options, translateItems):
				if (translateItems == true) // == true to account for null
					formatText = function(_) {return _t(id + "_" + value);};
				else
					formatText = function(_) {return value.toLowerCase() == "off" ? "OFF" : value;};
			case FloatOption(min, max, inc, wrap):
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

	public function change(left:Bool) {
		switch (type) {
			case IntOption(min, max, inc, wrap):
				inc ??= 1;
				inc *= left ? -1 : 1;
				wrap ??= false;

				final range = (max - min);
				var curVal:Float = value;
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Std.int(curVal);
			case FloatOption(min, max, inc, wrap):
				inc ??= 0.05;
				inc *= left ? -1 : 1;
				wrap ??= false;

				final range = (max - min);
				var curVal:Float = value;
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Math.round(curVal * powMult) / powMult;
			case BoolOption:
				value = !value;
			case ListOption(list, translateItems):
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
			return (controllerMode) ? Controls.gamepad_binds[id] : Controls.binds[id];
		return Reflect.field(Settings.data, id);
	}

	function set_value(v:Dynamic):Dynamic {
		if (type == KeyOption) {
		    if(controllerMode)
				Controls.gamepad_binds.set(id, v);
			else
			    Controls.binds.set(id, v);
		}
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