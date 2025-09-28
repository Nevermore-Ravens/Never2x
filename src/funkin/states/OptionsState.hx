package funkin.states;

import haxe.io.Path;
import funkin.shaders.TileLine;
import funkin.objects.ui.Border;
import funkin.objects.ui.SwirlBG;
import funkin.objects.NoteSplash;
import funkin.objects.FunkinSprite;
import funkin.objects.ui.CategoryList;
import flixel.input.keyboard.FlxKey;

class OptionsState extends FunkinState {
	public static var self:OptionsState;

	final categoryList:Array<String> = ["Keybinds", "Gameplay", "HUD", "Visuals", "Performance", "Misc."];
	final optionsList:Map<String, Array<Option>> = [
		"Keybinds" => [
			new Option("left_note", "left_note_desc", "note_left", KeyOption),
			new Option("down_note", "down_note_desc", "note_down", KeyOption),
			new Option("up_note", "up_note_desc", "note_up", KeyOption),
			new Option("right_note", "right_note_desc", "note_right", KeyOption),
			new Option("pause", "pause_desc", "pause", KeyOption),
			new Option("reset", "reset_desc", "reset", KeyOption),
			new Option("ui_left", "ui_left_desc", "ui_left", KeyOption),
			new Option("ui_down", "ui_down_desc", "ui_down", KeyOption),
			new Option("ui_up", "ui_up_desc", "ui_up", KeyOption),
			new Option("ui_right", "ui_right_desc", "ui_right", KeyOption),
			new Option("accept", "accept_desc", "accept", KeyOption),
			new Option("back", "back_desc", "back", KeyOption),
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
			new Option('scroll_dir', 'scroll_dir_desc', "scrollDirection", ListOption(["Up", "Down"])),
			new Option('scroll_speed', 'scroll_speed_desc', "scrollSpeed", FloatOption(0.5, 7, 0.05)),
			{
				var opt = new Option("note_skin", "<NO-LANG>What texture the notes will use in game.", "noteSkin", ListOption(['camv2', 'camv1', 'funkin', 'circle','voltexArrow', 'voltexCircle', 'voltexBar', 'holofunk']));
				opt.formatText = function(_) {
					return switch (opt.value) {
						case 'camv2': "Cam. V2";
						case 'camv1': "Cam. V1";
						case 'funkin': "Funkin";
						case 'circle': "Circles";
						case 'voltexArrow': "FNVX (Arrow)";
						case 'voltexCircle': "FNVX (Circle)";
						case 'voltexBar': "FNVX (Bar)";
						case 'holofunk': "Holofunk";
						default: "how'd you get out the list";
					}
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

				var opt = new Option("splash_skin", "<NO-LANG>What texture the note splashes will use in game.", "noteSplashSkin", ListOption(possibleNotesplashes));
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
			new Option("<NO-LANG>Judgement Counter", "<NO-LANG>If there will be a counter on the corner showing your judgement totals.", "judgementCounter", BoolOption),
			new Option('hit_error_bar', 'hit_error_bar_desc', "hitErrorBar", BoolOption),
			new Option("<NO-LANG>Combo Tinting","<NO-LANG>Allows the combo numbers to be tinted by judgements.", "comboTinting", ListOption(["Off", "Clear Flag", "Per-Note"])),
			new Option("<NO-LANG>Score Popup Center", "<NO-LANG>Where the judgements and combo are positioned. (WILL BE FORCED TO \"HUD\" WITH CENTERED NOTES!)", "popupCenter", ListOption(["Top", "Field", "HUD"])),
			new Option("<NO-LANG>Hide Accuracy", "<NO-LANG>Hides the accuracy % in the HUD", "hideAcc", BoolOption),
			new Option("hide_hud", "<NO-LANG>Makes the entire HUD disappear, if you want just the notes. Or if you're showcasing something.", "hideHUD", BoolOption),
			{
				var opt = new Option("judge_alpha", "<NO-LANG>How much you can see the judgements of the notes you hit.", "judgementAlpha", FloatOption(0, 1, 0.05));
					opt.formatText = function(_) {
						return (opt.value * 100) + "%";
					};
					opt;
			},
			{
				var opt = new Option("combo_alpha", "<NO-LANG>How much you can see the combo counter.", "comboAlpha", FloatOption(0, 1, 0.05));
				opt.formatText = function(_) {
					return (opt.value * 100) + "%";
				};
				opt;
			},
			{
				var opt = new Option("<NO-LANG>Health Bar Alpha", "<NO-LANG>How much you can see the the health bar in game.", "healthBarAlpha", FloatOption(0, 1, 0.05));
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
					for (i => cata in self.listGrp.texts.members)
						cata.text = _t(self.categoryList[i]).toUpperCase();

					if (self.selCategory >= 0) {
						for (i => txt in self.optTxt.members) {
							final opt = self.curOptList[i];
							txt.text = (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name)).toUpperCase();
							self.optValTxt.members[i].text = opt.formatText(i == self.curSelected);
						}

						self.lastDescHeight = self.descBG.scale.y;
						self.descTxt.text = self.getDesc(self.curOptList[self.curSelected]);
					}
				}
				opt;
			},
			new Option("flashing_lights", "<NO-LANG>If the game is allowed to risk seizures for fast colored effects.", "flashingLights", BoolOption),
			new Option('center_notes', 'center_notes_desc', "centeredNotes", BoolOption),
			new Option('opp_notes', 'opp_notes_desc', "opponentNotes", BoolOption),
			//and this is where i would put lane underlay ^_^...........IF I HAD ONE!!
			new Option("cam_zooms", "<NO-LANG>If the game is allowed to bump the camera every measure. If it's on \"Legacy\", it affects Week 2 only.", "cameraZooms", ListOption(["Default", "Legacy", "Off"])),
			new Option("cam_movement", "<NO-LANG>If hitting a note will shift the camera in the note's direction.", "notesMoveCamera", BoolOption),
			new Option('<NO-LANG>Strum Glow', '<NO-LANG>How the strums will glow when you hit a note.', 'strumGlow', ListOption(['Off', 'Judgement', 'Per-Note'])),
			new Option("can_unglow", "<NO-LANG>Whether or not the strum going back to static relies on the animation finishing or the player releasing the key.", "unglowOnAnimFinish", BoolOption),
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
				var opt = new Option("Antialiasing", "<NO-LANG>If textures will have a linear transition between pixels instead of instant.", "antialiasing", BoolOption);
				opt.onChange = function(v) {
					for (i => obj in self.border.members)
						obj.antialiasing = v;

					for (i => cata in self.listGrp.texts.members)
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
			new Option("<NO-LANG>Audio Streams", "<NO-LANG>If music will load as it plays or simply load all at once.", "audioStreams", BoolOption),
			{
				var opt = new Option("reduced_quality", "<NO-LANG>If the game can cut out a few things for less work.", "reducedQuality", BoolOption);
				opt.onChange = function(v) {
				self.lineBG.shader = v ? null : self.lineShader;
						}
				opt;
			},
			{
				var opt = new Option("game_alpha", "<NO-LANG>How much you can see the visuals behind the HUD.", "gameVisibility", IntOption(0, 100, 5));
				opt.formatText = function(_) {
						return opt.value + "%";
				};
				opt;
			},
			new Option('videos', '<NO-LANG>Whether the game can run videos or not. Can impact performance/load times if enabled.', 'videos', BoolOption),
			new Option("reflections", "<NO-LANG>If some characters will shine reflections on the stage.", "reflections", BoolOption),
			new Option("shaders", "<NO-LANG>If some sprites can use special code to create special visuals.", "shaders", BoolOption),
			new Option("hold_grain", "<NO-LANG>How many times the game will compress sustain vertices. Higher Values will stretch the hold graphic for more performance.", "holdGrain", IntOption(1, 8, 1)),
			{
				var opt = new Option("gpu_cache", "<NO-LANG>If the game will use VRAM for texture storage to reduce RAM.\n\n(1GB OF VRAM RECOMMENDED, WILL RESTART IF CHANGED.)", "gpuCache", BoolOption);
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
				var opt = new Option("fps_counter", "<NO-LANG>If the will show a counter in the corner of your framerate.", 'fpsCounter', BoolOption);
				opt.onChange = function(v) {
						Main.fpsCounter.visible = v;
				};
				opt;
			},
			{
				var opt = new Option("fullscreen", "<NO-LANG>Whether or not the game will take all of your screen space.", "fullscreen", BoolOption);
				opt.onChange = function(v) {
						FlxG.fullscreen = v;
				};
				opt;
			}, 
			{
				var opt = new Option("<NO-LANG>Discord RPC", "<NO-LANG>If the game can connect to your Discord client and display that you are playing VS Camellia.", "discordRPC", BoolOption);
				opt.onChange = function(_) DiscordClient.check();
				opt;
			},
			{
				var opt = new Option("<NO-LANG>Auto Pause", "<NO-LANG>If the game will freeze when unfocused.", "autoPause", BoolOption);
				opt.onChange = function(v) {
						FlxG.autoPause = v;
				};
				opt;
			},
			new Option("close_animation", "<NO-LANG>If the game should fade out when closed.", "closeAnimation", BoolOption),
			{
				var opt = new Option("<NO-LANG>Calibrate Offset", "<NO-LANG>Find your offset automatically.", "", ButtonOption);
				opt.onChange = function(_) FlxG.switchState(new CalibrateOffsetState());
				opt;
			}
		]
	];

	public static var inPlayState:Bool = false;
	var selCategory:Int = -1;
	var curSelected:Int = 0;

	// 0 - None, 1 - Left, 2 - Right, 3 - Mouse Left, 4 - Mouse Right
	var curHolding:Int = 0;
	var holdWait:Float = 0.5;

	var waitingForKey:Bool = false;

	var curOptList(get, never):Array<Option>;
	function get_curOptList() {
		return optionsList[categoryList[selCategory]];
	}

	var bg:SwirlBG;
	var lineBG:FunkinSprite;
	var lineShader:TileLine;
	var border:Border;

	var listGrp:CategoryList;

	var curOptScroll:Float = 0;
	var optScrollInc:Float = 0;
	var selOptScale:Float = 0;
	var optBG:FunkinSprite;
	var optSel:FunkinSprite;
	var optArrLeft:FunkinSprite;
	var optArrRight:FunkinSprite;
	var optTxt:FlxTypedGroup<FlxText>;
	var optValTxt:FlxTypedGroup<FlxText>;

	var lastDescHeight:Float = 0;
	var descBG:FunkinSprite;
	var descTxt:FlxText;

	override function create() {
		super.create();
		self = this;

		add(bg = new SwirlBG(0xFF79CCFC, 0xFF003D7A));

		lineBG = new FunkinSprite();
		lineBG.makeGraphic(FlxG.width, FlxG.height, 0x70000000);
		lineShader = new TileLine();
		lineShader.color1.value = [0, 0, 0, 0.375];
		lineShader.color2.value = [0, 0, 0, 0.5];
		lineShader.density.value = [200.0];
		lineShader.time.value = [SwirlBG.time / 64];
		lineBG.shader = (!Settings.data.reducedQuality) ? lineShader : null;
		add(lineBG);

		var optionsTile = new flixel.addons.display.FlxBackdrop(Paths.image('menus/Options/bigText'), Y);
		optionsTile.x = FlxG.width - optionsTile.width;
		optionsTile.velocity.y = 25;
		add(optionsTile);

		add(listGrp = new CategoryList(20, 120, categoryList));
		listGrp.open = openCategory;
		listGrp.onRetarget = (i) -> {bg.speed = 5;};

		add(optBG = new FunkinSprite(listGrp.x + listGrp.width + 25, listGrp.y).makeGraphic(1, 440, 0x70000000));
		optBG.scale.set(795, 0);
		optBG.updateHitbox();
		optBG.offset.set();
		optBG.origin.set();

		add(optSel = new FunkinSprite(optBG.x - 4, optBG.y).makeGraphic(1, 1, 0xFFFFFFFF));
		optSel.scale.set(optBG.width + 8, 55);
		optSel.updateHitbox();
		optSel.scale.y = 0;

		add(optArrLeft = new FunkinSprite(optSel.x, optSel.y, Paths.image("menus/Options/arrow")));
		optArrLeft.scale.y = 0;

		add(optArrRight = new FunkinSprite(optSel.x + optSel.width, optSel.y, Paths.image("menus/Options/arrow")));
		optArrRight.flipX = true;
		optArrRight.scale.y = 0;
		optArrRight.x -= optArrRight.width;

		add(optValTxt = new FlxTypedGroup<FlxText>());
		add(optTxt = new FlxTypedGroup<FlxText>());

		add(descBG = new FunkinSprite(optBG.x, FlxG.height - 20 - 120).makeGraphic(1, 1, 0x70000000));
		descBG.scale.set(optBG.scale.x, 120);
		descBG.updateHitbox();
		descBG.scale.y = 0;
		descBG.offset.set();
		descBG.origin.set();

		add(descTxt = new FlxText(descBG.x + 15, descBG.y + 25, descBG.width - 30, ""));
		descTxt.setFormat(Paths.font("Rockford-NTLG Extralight.ttf"), 20, 0xFFFFFFFF, LEFT);

		add(border = new Border(true, "CONFIGURE YOUR SETTINGS • ", "Options"));
		Border.transitionTween(true, true, border);
	}

	override function update(delta:Float) {
		super.update(delta);

		if (!Settings.data.reducedQuality)
			lineShader.time.value[0] = SwirlBG.time / 64;
		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);

		if (waitingForKey && !listGrp.enterHit) {
			final opt = curOptList[curSelected];
			final keys:Array<FlxKey> = cast opt.value;
			if (FlxG.keys.justPressed.ESCAPE) {
				waitingForKey = false;
				FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));

				optValTxt.members[curSelected].text = opt.formatText(true);
				descTxt.text = getDesc(curOptList[curSelected]);
				return;
			} else if (opt.curKey < keys.length && FlxG.keys.justPressed.DELETE) {
				waitingForKey = false;
				FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
				
				keys.splice(opt.curKey, 1);
				opt.value = keys;

				optValTxt.members[curSelected].text = opt.formatText(true);
				descTxt.text = getDesc(curOptList[curSelected]);
				return;
			}

			var key = FlxG.keys.firstJustPressed();
			if (key != -1) {
				waitingForKey = false;
				if (opt.curKey == keys.length)
					keys.push(key);
				else
					keys[opt.curKey] = key;
				opt.value = keys;

				FlxG.sound.play(Paths.audio("popup_select", 'sfx'));
				optValTxt.members[curSelected].text = opt.formatText(true);
				descTxt.text = getDesc(curOptList[curSelected]);
			}
		} else if (selCategory > -2 && !listGrp.enterHit) {
			if (selCategory >= 0) 
				optInputs(delta);
			else if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
				descTxt.text = "";
				selCategory = -2;
				listGrp.useMouse = listGrp.useInputs = false;
				listGrp.targetScale = 0;
				FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));

				Border.transitionTween(true, false, border, 0.25, 0.25, function() {
					if (inPlayState) FlxG.switchState(new PlayState());
					else FlxG.switchState(new MainMenuState());
				});
			}
		}


		optBG.scale.y = FlxMath.lerp(optBG.scale.y, (selCategory < 0 ? 0 : 1), delta * 15);
		descBG.scale.y = descBG.height * optBG.scale.y;
		@:privateAccess descTxt.regenGraphic();
		if (descBG.scale.y > 26) {
			descTxt.clipGraphic(0, 0, descTxt.graphic.width, Math.min(descBG.scale.y - 25, descTxt.graphic.height));
			descTxt.visible = true;
		} else
			descTxt.visible = false;

		curOptScroll = FlxMath.lerp(curOptScroll, optScrollInc * curSelected, delta * 15);
		final optMargin = (optBG.y + optBG.frameHeight * optBG.scale.y);
		var curOptY = optBG.y + 25 - curOptScroll;
		for (i in 0...optTxt.members.length) {
			final txt = optTxt.members[i];
			final val = optValTxt.members[i];
			@:privateAccess {
				txt.regenGraphic();
				val.regenGraphic();
			}

			txt.origin.x = 0;
			val.origin.x = val.frameWidth;
			txt.scale.x = txt.scale.y = FlxMath.lerp(txt.scale.x, (i == curSelected ? 1.0 : 0.85), delta * 15);
			val.scale.copyFrom(txt.scale);
			final scale = ((txt.scale.y - 0.85) / 0.15);

			curOptY += 10 * scale;
			txt.y = curOptY;
			val.x = optBG.x + optBG.width - 20 - val.width;
			val.y = txt.y + (txt.height - val.height) * 0.5 + ((i == curSelected) ? 3 * scale : 0);
			curOptY += 35 + 10 * scale;

			// clip it to the list.
			final top = txt.y + (txt.graphic.height - txt.graphic.height * txt.scale.y) * 0.5;
			final bot = (top + txt.graphic.height * txt.scale.y);
			if (bot > optBG.y + 5 && top < optMargin - 5) {
				final topClip = Math.max(optBG.y - top, 0);
				txt.clipGraphic(0, topClip / txt.scale.y, txt.graphic.width, txt.graphic.height - (Math.max(bot - optMargin, 0) + topClip) / txt.scale.y);
				txt.offset.y = -topClip;
				txt.visible = true;
			} else
				txt.visible = false;

			final valTop = val.y + (val.graphic.height - val.graphic.height * val.scale.y) * 0.5;
			final valBot = (valTop + val.graphic.height * val.scale.y);
			final valTopMargin = (i == curSelected) ? Math.max(optSel.y + (optSel.height - optSel.scale.y) * 0.5, optBG.y) : optBG.y;
			final valBotMargin = (i == curSelected) ? Math.min(optSel.y + (optSel.height + optSel.scale.y) * 0.5, optMargin) : optMargin;
			final valTopClip = Math.max(valTopMargin - valTop, 0);
			if (valBot > valTopMargin + 5 && valTop < valBotMargin - 5) {
				final leftClip = Math.max(optSel.x - val.x, 0) / val.scale.x;
				val.clipGraphic(leftClip, valTopClip / val.scale.y, val.graphic.width - leftClip, val.graphic.height - (Math.max(valBot - valBotMargin, 0) + valTopClip) / val.scale.y);
				val.offset.x = -leftClip;
				val.offset.y = -valTopClip;
				val.visible = true;
			} else
				val.visible = false;
		}

		selOptScale = Math.min(Math.max(selOptScale + delta * (selCategory < 0 ? -8 : 4), 0.0), 1.0);
		final easedScale = FlxEase.backOut(selOptScale);
		optSel.scale.y = optSel.height * easedScale;
		optArrLeft.scale.y = optArrRight.scale.y = easedScale;
		
		if (selCategory < 0) return;
		
		// descBG.scale.y = FlxMath.lerp(lastDescHeight, descTxt.height + 50, FlxEase.backOut(selOptScale));
		optSel.y = optTxt.members[curSelected].y + (optTxt.members[curSelected].height - optSel.height) * 0.5;
		optArrLeft.y = optArrRight.y = optSel.y;
	}

	function openCategory(cata:Int) {
		if (cata == selCategory) {
			FlxG.sound.play(Paths.audio("menu_toggle", 'sfx'));
			return;
		}

		listGrp.useInputs = false;
		listGrp.selected = cata;
		selCategory = cata;

		while (optTxt.length > 0) {
			final txt = optTxt.members[0];
			final val = optValTxt.members[0];
			optTxt.remove(txt, true);
			optValTxt.remove(val, true);
			txt.destroy();
			val.destroy();
		}

		curSelected = 0;
		var y = optBG.y + 25;
		for (i => opt in curOptList) {
			var txt = new FlxText(optBG.x + 20, y, optBG.width - 40, (opt.name.startsWith("<NO-LANG>") ? opt.name.substring(9, opt.name.length) : _t(opt.name)).toUpperCase());
			var val = new FlxText(txt.x, txt.y, 0, opt.formatText(i == curSelected));

			if (i == curSelected) {
				txt.y += 10;
				val.y += 10;
				txt.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 30, 0xFF101010, LEFT);
				val.setFormat(Paths.font("Rockford-NTLG Medium.ttf"), 80, 0xFFC7C7C7, RIGHT);
				//y += 55;
			} else {
				txt.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 30, 0xFFFFFFFF, LEFT);
				txt.updateHitbox();
				//txt.scale.x = 0.85;
				txt.origin.x = 0;

				val.setFormat(Paths.font("Rockford-NTLG Light.ttf"), 30, 0xFFFFFFFF, RIGHT);
				val.updateHitbox();
				// val.scale.x = 0.85;
				val.origin.x = val.frameWidth;
				//y += 35;
			}
			txt.scale.set();
			val.scale.set();
			txt.antialiasing = Settings.data.antialiasing;
			val.antialiasing = Settings.data.antialiasing;
			optTxt.add(txt);
			optValTxt.add(val);
		}
		optScrollInc = Math.max(curOptList.length * 35 + 60 - optBG.frameHeight, 0) / curOptList.length;

		lastDescHeight = descBG.scale.y;
		descTxt.text = getDesc(curOptList[curSelected]);

		FlxG.sound.play(Paths.audio("popup_appear", 'sfx')); // combo sounds baybee
		FlxG.sound.play(Paths.audio("menu_toggle", 'sfx'));
	}

	function getDesc(opt:Option) {
		return (opt.desc.startsWith("<NO-LANG>") ? opt.desc.substring(9, opt.desc.length) : _t(opt.desc)) + (opt.type == KeyOption ? "\n\n" + _formatT("key_opt_desc", [",", _t("accept").toUpperCase()]) : "");
	}

	function retargetOpt(target:Int) {
		if (target == curSelected) return;

		optTxt.members[curSelected].color = 0xFFFFFFFF;
		optTxt.members[curSelected].font = Paths.font("Rockford-NTLG Light.ttf");
		optValTxt.members[curSelected].text = curOptList[curSelected].formatText(false);
		optValTxt.members[curSelected].size = 30;
		optValTxt.members[curSelected].color = 0xFFFFFFFF;
		optValTxt.members[curSelected].font = Paths.font("Rockford-NTLG Light.ttf");	

		curSelected = target;
		optSel.scale.y = 0;
		selOptScale = 0;

		optTxt.members[curSelected].color = 0xFF101010;
		optTxt.members[curSelected].font = Paths.font("Rockford-NTLG Medium.ttf");	
		optValTxt.members[curSelected].text = curOptList[curSelected].formatText(true);
		optValTxt.members[curSelected].size = 80;
		optValTxt.members[curSelected].color = 0xFFC7C7C7;
		optValTxt.members[curSelected].font = Paths.font("Rockford-NTLG Medium.ttf");

		lastDescHeight = descBG.scale.y;
		descTxt.text = getDesc(curOptList[curSelected]);

		bg.speed = 5;
		FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
	}

	function optInputs(delta:Float) {
		if (FlxG.mouse.screenX >= optSel.x && FlxG.mouse.screenX <= optSel.x + optSel.width) {
			for (i in 0...optTxt.length) {
				var txt = optTxt.members[i];
				var height = 35 + 20 * ((txt.scale.y - 0.85) / 0.15);
				
				var top = txt.y + (txt.height - height) * 0.5;
				if (FlxG.mouse.screenY >= top && FlxG.mouse.screenY <= top + height) {
					retargetOpt(listGrp.mouseMoved ? i : curSelected);
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
							FlxG.sound.play(Paths.audio("popup_appear", 'sfx'));
							optValTxt.members[curSelected].text = "Setting...";
						} else if (Math.abs(FlxG.mouse.screenX - (optSel.x + optSel.width * 0.5)) >= optSel.width * 0.5 - 25) {
							final isLeft = FlxG.mouse.screenX <= optSel.x + 25;
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
		}

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		final leftJustPressed:Bool = Controls.justPressed('ui_left');

		if (downJustPressed || Controls.justPressed('ui_up'))
			retargetOpt(FlxMath.wrap(curSelected + (downJustPressed ? 1 : -1), 0, curOptList.length - 1));

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
				FlxG.sound.play(Paths.audio("popup_appear", 'sfx'));
				optValTxt.members[curSelected].text = "Setting...";
			} else if (curOption.type == ButtonOption) curOption.change(false);
		}

		if (Controls.justPressed("back") || FlxG.mouse.justPressedRight) {
			selCategory = -1;
			listGrp.useInputs = true;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
		}
	}

	override function destroy() {
		super.destroy();
		Controls.save();
		Settings.save();
		self = null;
	}
}

enum OptionType {
	IntOption(min:Int, max:Int, ?inc:Int, ?wrap:Bool);
	FloatOption(min:Float, max:Float, ?inc:Float, ?wrap:Bool);
	BoolOption;
	ListOption(options:Array<String>);
	KeyOption;
	ButtonOption;
}

class Option {
	public var name:String;
	public var desc:String;
	public var sound:String = "menu_setting_tick";

	public var id:String;
	public var type:OptionType;
	@:isVar public var value(get, set):Dynamic;

	//type specific
	public var powMult:Float = 1;
	public var curKey:Int = 0;
	
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
				sound = "menu_toggle";
				formatText = function(_) {
					return _t(value ? "on" : "off").toUpperCase();
				};
			case KeyOption:
				formatText = function(selected) {
					final keys:Array<FlxKey> = cast value;
					return selected ? (curKey == keys.length ? 'New Key' : '#${curKey + 1} (${formatKey(keys[curKey])})') : [for (key in keys) formatKey(key)].join(", ");
				};
			case ButtonOption:
				formatText = function(_) {return "";};
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
			case ListOption(list):
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

	function get_value():Dynamic {
		if (type == KeyOption)
			return Controls.binds[id];
		return Reflect.field(Settings.data, id);
	}

	function set_value(v:Dynamic):Dynamic {
		if (type == KeyOption)
			Controls.binds.set(id, v);
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
}