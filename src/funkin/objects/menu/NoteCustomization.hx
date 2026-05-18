package funkin.objects.menu;

import funkin.shaders.GradMask;
import funkin.shaders.HueGrad;
import funkin.states.OptionsState;
import funkin.backend.NoteSkin;
import funkin.objects.NoteSplash;
import haxe.io.Path;

class NoteCustomization extends OptionList {
    var notes:FlxTypedGroup<Note>;
	var hoverNote:Int = -1;
	var curNote:Int = 0;
	var bigNote:Note;

	// from experience, setting a color to pitch black can screw up these values.
	var curCol:Array<Int> = [0, 0, 0];
	var rgb:Bool = false;
	var holdingCol:Bool = false;
	var colTxts:FlxTypedGroup<FlxText>;
	var colVals:FlxTypedGroup<FlxText>;
	var colHover:FunkinSprite;
	var wheels:FlxTypedGroup<FunkinSprite>;
	var shaders:Array<GradMask> = [];
	var hueShader:HueGrad;
	var colWarning:FlxText;

    var noteSelIdx:Int;
    var noteColIdx:Int;
    var noteActIdx:Int;

    public function new(x:Float, y:Float, width:Float, height:Float) {
        super(x, y, width, height);

        notes = new FlxTypedGroup();
		final lumin = Settings.data.quantColouring != "None";
		if (Settings.data.quantColouring.startsWith("Custom")) {
			Note.byQuant = Settings.data.quantColouring == "Custom";
			Note.curPalette = Note.byQuant ? Settings.data.customQuants : Settings.data.customColumns;
		} else {
			Note.byQuant = lumin;
			Note.curPalette = Note.byQuant && Note.quantPalettes.exists(Settings.data.quantColouring) ? Note.quantPalettes[Settings.data.quantColouring].copy() : getDefaultColumns();
		}
		final centerIdx:Float = Note.byQuant ? 5.5 : 2;
		for (i in 0...Settings.data.customQuants.length) {
			var note = new Note();
			note.data.lane = i % 4;
			note.luminColors = lumin;
			note.skin = '';
			note.setPosition(FlxG.width * 1.5 + 160 * 0.55 * (i - centerIdx), 0);
			scaleNote(note, 0.55);
			note.updateHitbox();
			note.y += ((160 * 0.55) - note.height) * 0.5;
			note.color = lumin ? Note.curPalette[Std.int(Math.min(i, Note.curPalette.length - 1))] : 0xFFFFFFFF;
			note.alpha = (Note.byQuant || i < 4) ? 1 : 0;
			notes.add(note);
		}

		bigNote = new Note();
		bigNote.data.lane = notes.members[curNote].data.lane;
		bigNote.luminColors = notes.members[curNote].luminColors;
		bigNote.skin = '';
		scaleNote(bigNote, 1.5);
		bigNote.updateHitbox();
		bigNote.setPosition(FlxG.width + 250, 370 + ((160 * 1.5) - bigNote.height) * 0.5);
		bigNote.color = notes.members[curNote].color;

		colHover = new FunkinSprite();
		colHover.makeGraphic(1, 1, 0xFFFFFFFF);

		var names = ["hue", "sat", "val"];
		wheels = new FlxTypedGroup<FunkinSprite>();
		colVals = new FlxTypedGroup<FlxText>();
		colTxts = new FlxTypedGroup<FlxText>();
		for (i in 0...3) {
			var wheel = new FunkinSprite(x + 740, (i == 0) ? 370 : wheels.members[i - 1].y + wheels.members[i - 1].height + 60);
			wheel.makeGraphic(1, 1, 0xFFFFFFFF);
			wheel.scale.set(390, 35);
			wheel.updateHitbox();
			shaders.push(new GradMask());
			wheel.shader = shaders[shaders.length - 1];
			wheels.add(wheel);

			var txt = new FlxText(wheel.x, wheel.y - 5, wheel.width, _t(names[i]));
			txt.setFormat(Paths.font("cafeSquare.ttf"), 20, 0xFFFFFFFF, LEFT);
			txt.y -= txt.height;
			colTxts.add(txt);

			var val = new FlxText(txt.x, txt.y, txt.fieldWidth, Std.string(curCol[i]));
			val.setFormat(Paths.font("cafeSquare.ttf"), 20, 0xFFFFFFFF, RIGHT);
			colVals.add(val);
		}

		wheels.members[0].shader = hueShader = new HueGrad();
		updateColor();

		colHover.setPosition(colTxts.members[0].x - 4, colTxts.members[0].y - 4);
		colHover.scale.set(wheels.members[0].width + 8, (wheels.members[0].y + wheels.members[0].height + 4) - (colTxts.members[0].y - 4));
		colHover.origin.set();

        onOptMove = noteOptMove;
        onSelect = (_, __) -> holdingCol = false;
        setOptions([
            {
                final possible: Array<String> = [];
                final names: Map<String, String> = [];
                for (path in Paths.readDirectory("data/noteSkins"))
                    if (path.endsWith(".json5") || path.endsWith(".json")) {
                        var name:String = Path.withoutDirectory(Path.withoutExtension(path));
                        if(name == "default" || possible.contains(name)) continue;
                        var data = NoteSkin.get(name);
                        possible.push(name);
                        names.set(name, data.displayName);
                    }
    
                var opt = new Option("note_skin", "note_skin_desc", "noteSkin", ListOption(possible, true));
                opt.formatListOption = function(val, _) {
                    return names[val];
                };
                opt.onChange = function(v) {
                    var newStyle = null;
                    for (i => opt in list) {
                        if (opt.id != "noteSkinStyle") continue;
    
                        final data = NoteSkin.get(v);
                        final possible: Array<String> = [];
                        final names: Map<String, String> = [];
                        for (name in data.styleOrder) {
                            if (name == "default" || possible.contains(name)) continue;
                            possible.push(name);
                            names.set(name, data.styles[name].displayName);
                        }
                        possible.unshift("default");
                        names.set("default", "Default (By Context)");
    
                        opt.type = ListOption(possible, true);
                        opt.formatListOption = function(item, _) {
                            return names[item];
                        };
    
                        if (!possible.contains(Settings.data.noteSkinStyle)) {
                            Settings.data.noteSkinStyle = "default";
                            newStyle = "normal";
                            components[i].change(opt);
                        }
                    }
    
                    final lumin = Settings.data.quantColouring != "None";
                    for (note in notes) {
                        @:bypassAccessor note.style = (newStyle == null ? note.style : newStyle);
                        note.skin = '';
                        scaleNote(note, 0.55);
                        note.updateHitbox();
    
                        if (!lumin && note.luminColors) {
                            note.luminColors = false;
                            note.color = 0xFFFFFFFF;
                        }
                    }
                    @:bypassAccessor bigNote.style = (newStyle == null ? bigNote.style : newStyle);
                    bigNote.skin = '';
                    scaleNote(bigNote, 1.5);
                    bigNote.updateHitbox();
                    if (!lumin && bigNote.luminColors) {
                        bigNote.luminColors = false;
                        bigNote.color = 0xFFFFFFFF;
                    }
    
                    position(0);
                    if (!lumin) {
                        Note.curPalette = getDefaultColumns();
                        changeNote(0);
                    }
                }
                opt;
            },
            {
                final data = NoteSkin.get(Settings.data.noteSkin);
                final possible: Array<String> = [];
                final names: Map<String, String> = [];
                for (name in data.styleOrder) {
                    if (name == "default" || possible.contains(name)) continue;
                    possible.push(name);
                    names.set(name, data.styles[name].displayName);
                }
                possible.unshift("default");
                names.set("default", "Default (By Context)");
    
                var opt = new Option("note_skin_style", "note_skin_style_desc", "noteSkinStyle", ListOption(possible, true));
                opt.formatListOption = function(item, _) {
                    return names[item];
                };
                opt.onChange = function(v) {
                    final style = v == "default" ? "normal" : v;
                    final lumin = Settings.data.quantColouring != "None";
                    for (note in notes) {
                        note.style = style;
                        scaleNote(note, 0.55);
                        note.updateHitbox();
    
                        if (!lumin && note.luminColors) {
                            note.luminColors = false;
                            note.color = 0xFFFFFFFF;
                        }
                    }
                    bigNote.style = style;
                    scaleNote(bigNote, 1.5);
                    bigNote.updateHitbox();
                    bigNote.y = y + 370 + ((160 * 1.5) - bigNote.height) * 0.5;
                    if (!lumin && bigNote.luminColors) {
                        bigNote.luminColors = false;
                        bigNote.color = 0xFFFFFFFF;
                    }
    
                    position(0);
                    if (!lumin) {
                        Note.curPalette = getDefaultColumns();
                        changeNote(0);
                    }
                }
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
    
                var opt = new Option("splash_skin", "splash_skin_desc", "noteSplashSkin", ListOption(possibleNotesplashes, true));
                opt.formatListOption = function(val, _) {
                    return notesplashNames.get(val) ?? 'Fallback (${val})'; // Display the name so you can figure out what the splash WAS
                };
                opt;
            },
            { // this can be reverted if the order of the quants matter
                var quantPalettes: Array<String> = [];
                for(name in funkin.objects.Note.quantPalettes.keys())
                    quantPalettes.push(name);
    
                quantPalettes.unshift('Custom (Columns)');
                quantPalettes.unshift('Custom');
                quantPalettes.unshift('None');
    
                var opt = new Option('quant_col', 'quant_col_desc', "quantColouring", ListOption(quantPalettes, true));
                opt.onChange = function(v) {
                    final lumin = v != "None";
                    if (v.startsWith("Custom")) {
                        Note.byQuant = v == "Custom";
                        Note.curPalette = Note.byQuant ? Settings.data.customQuants : Settings.data.customColumns;
                    } else {
                        Note.byQuant = lumin;
                        Note.curPalette = Note.byQuant && Note.quantPalettes.exists(v) ? Note.quantPalettes[v].copy() : getDefaultColumns();
                    }
                    
                    for (i => note in notes) {
                        if (!lumin || i < Note.curPalette.length)
                            note.color = lumin ? Note.curPalette[i] : 0xFFFFFFFF;
                        if (note.luminColors != lumin) {
                            note.luminColors = lumin;
                            note.skin = '';
                            scaleNote(note, 0.55);
                            note.updateHitbox();
                        }
                    }
                    bigNote.color = notes.members[curNote].color;
                    if (bigNote.luminColors != lumin) {
                        bigNote.luminColors = lumin;
                        bigNote.skin = '';
                        scaleNote(bigNote, 1.5);
                        bigNote.updateHitbox();
                    }
                    
                    // actions[0] = v.startsWith("Custom") ? "reset" : "apply_custom";
                    // actionTxt.members[0].text = _t(actions[0]).toUpperCase();
                    // actionTxt.members[0].offset.x = actionTxt.members[0].width * 0.5;
                    changeNote(0);
                }
                opt;
            },
            {
                var opt = new Option("<NO-LANG> ", "<NO-LANG> ", "NOTE_SELECT", ButtonOption);
                opt.hasMove = true;
                opt;
            },
            {
                var opt = new Option("<NO-LANG> ", "<NO-LANG> ", "NOTE_EDIT_COL_0", ButtonOption);
                opt.hasMove = true;
                opt;
            },
            {
                var opt = new Option("<NO-LANG> ", "<NO-LANG> ", "NOTE_EDIT_COL_1", ButtonOption);
                opt.hasMove = true;
                opt;
            },
            {
                var opt = new Option("<NO-LANG> ", "<NO-LANG> ", "NOTE_EDIT_COL_2", ButtonOption);
                opt.hasMove = true;
                opt;
            },
            {
                var opt = new Option("<NO-LANG> ", "<NO-LANG> ", "NOTE_ACTION", ButtonOption);
                opt.hasMove = true;
                opt;
            }
        ]);

        for (i => opt in list) {
            switch (opt.id) {
                case "NOTE_SELECT": noteSelIdx = i;
                case "NOTE_EDIT_COL_0": noteColIdx = i;
                case "NOTE_ACTIONS": noteActIdx = i;
            }
        }
    }

    function noteOptMove(current:Int, left:Bool) {
        final inc = left ? -1 : 1;
        switch (list[current].id) {
            case "NOTE_SELECT":
                FlxG.sound.play(Paths.audio("scroll", "sfx"));
                changeNote(inc);
            case "NOTE_EDIT_COL_0":
                FlxG.sound.play(Paths.audio("scroll", "sfx"));
                editColor(0, Std.int(FlxMath.bound(curCol[0] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, rgb ? 255 : 360)));
            case "NOTE_EDIT_COL_1":
                FlxG.sound.play(Paths.audio("scroll", "sfx"));
                editColor(1, Std.int(FlxMath.bound(curCol[1] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, rgb ? 255 : 100)));
            case "NOTE_EDIT_COL_2":
                FlxG.sound.play(Paths.audio("scroll", "sfx"));
                editColor(2, Std.int(FlxMath.bound(curCol[2] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, rgb ? 255 : 100)));
            case "NOTE_ACTIONS":
        }
    }

	function updateColor() {
		if (rgb) {
			curCol[0] = Note.curPalette[curNote].red;
			curCol[1] = Note.curPalette[curNote].green;
			curCol[2] = Note.curPalette[curNote].blue;

			for (i in 0...shaders.length) {
				shaders[i].fromCol.value = [(i == 0 ? 0 : curCol[0] / 255), (i == 1 ? 0 : curCol[1] / 255), (i == 2 ? 0 : curCol[2] / 255), 1];
				shaders[i].toCol.value = [(i == 0 ? 1 : curCol[0] / 255), (i == 1 ? 1 : curCol[1] / 255), (i == 2 ? 1 : curCol[2] / 255), 1];
			}

			for (i => val in colVals)
				val.text = Std.string(curCol[i]);

			return;
		}

		if (Note.curPalette[curNote].rgb == 0x000000) {
			curCol[0] = 0;
			curCol[1] = 100;
			curCol[2] = 0;
		} else {
			curCol[0] = Math.floor(Note.curPalette[curNote].hue);
			curCol[1] = Math.floor(Note.curPalette[curNote].saturation * 100);
			curCol[2] = Math.floor(Note.curPalette[curNote].brightness * 100);
		}

		hueShader.sat.value = [curCol[1] * 0.01];
		hueShader.brt.value = [curCol[2] * 0.01];

		var satCol = FlxColor.fromHSB(curCol[0], 0, curCol[2] * 0.01);
		shaders[1].fromCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
		satCol.setHSB(curCol[0], 1, curCol[2] * 0.01, 1);
		shaders[1].toCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];

		var brtCol = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, 0);
		shaders[2].fromCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
		brtCol.setHSB(curCol[0], curCol[1] * 0.01, 1, 1);
		shaders[2].toCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];

		for (i => val in colVals)
			val.text = Std.string(curCol[i]);
	}

	function changeNote(inc:Int) {
		curNote = FlxMath.wrap(curNote + inc, 0, Note.byQuant ? notes.length - 1 : 3);

		bigNote.luminColors = notes.members[curNote].luminColors;
		bigNote.color = notes.members[curNote].color;
		bigNote.data.lane = notes.members[curNote].data.lane;
		bigNote.reload(bigNote.styleData);
		scaleNote(bigNote, 1.5);
		bigNote.updateHitbox();
		bigNote.y = 370 + ((160 * 1.5) - bigNote.height) * 0.5;
		updateColor();

		/*checkCanApply();
		if (!actionTxt.members[0].visible && curAction == 0) {
			curAction = 1;

			actionTxt.members[0].color = 0xFFFFFFFF;
			actionTxt.members[0].font = Paths.font('Rockford-NTLG Light.ttf');
			if (curRow == 3) { // most likely not but just in case
				actionTxt.members[curAction].color = 0xFF000000;
				actionTxt.members[curAction].font = Paths.font('Rockford-NTLG Medium.ttf');
			}
		}*/
	}
	function editColor(idx:Int, to:Int) {
		curCol[idx] = to;
		colVals.members[idx].text = Std.string(curCol[idx]);

		notes.members[curNote].luminColors = bigNote.luminColors = true;
		if (rgb) {
			notes.members[curNote].color = bigNote.color = Note.curPalette[curNote] = FlxColor.fromRGB(curCol[0], curCol[1], curCol[2]);
			//checkCanApply();

			for (i in 0...shaders.length) {
				if (i == idx) continue;
				shaders[i].fromCol.value = [(i == 0 ? 0 : curCol[0] / 255), (i == 1 ? 0 : curCol[1] / 255), (i == 2 ? 0 : curCol[2] / 255), 1];
				shaders[i].toCol.value = [(i == 0 ? 1 : curCol[0] / 255), (i == 1 ? 1 : curCol[1] / 255), (i == 2 ? 1 : curCol[2] / 255), 1];
			}

			return;
		}

		notes.members[curNote].color = bigNote.color = Note.curPalette[curNote] = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, curCol[2] * 0.01);
		//checkCanApply();
		switch (idx) {
			case 0:
				var satCol = FlxColor.fromHSB(curCol[0], 0, curCol[2] * 0.01);
				shaders[1].fromCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
				satCol.setHSB(curCol[0], 1, curCol[2] * 0.01, 1);
				shaders[1].toCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
		
				var brtCol = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, 0);
				shaders[2].fromCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
				brtCol.setHSB(curCol[0], curCol[1] * 0.01, 1, 1);
				shaders[2].toCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
			case 1:
				hueShader.sat.value = [curCol[1] * 0.01];

				var brtCol = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, 0);
				shaders[2].fromCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
				brtCol.setHSB(curCol[0], curCol[1] * 0.01, 1, 1);
				shaders[2].toCol.value = [brtCol.redFloat, brtCol.greenFloat, brtCol.blueFloat, 1];
			case 2:
				hueShader.brt.value = [curCol[2] * 0.01];

				var satCol = FlxColor.fromHSB(curCol[0], 0, curCol[2] * 0.01);
				shaders[1].fromCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
				satCol.setHSB(curCol[0], 1, curCol[2] * 0.01, 1);
				shaders[1].toCol.value = [satCol.redFloat, satCol.greenFloat, satCol.blueFloat, 1];
		}
	}
	function checkCanApply() {
		final isCustom = Settings.data.quantColouring.startsWith("Custom");
		final data = isCustom ? Settings.default_data : Settings.data;
		//actionTxt.members[0].visible = Note.curPalette[curNote] != (Note.byQuant ? data.customQuants : data.customColumns)[curNote];

		colWarning.visible = !isCustom && Note.curPalette[curNote] != (Note.byQuant ? Note.quantPalettes[Settings.data.quantColouring] : getDefaultColumns())[curNote];
	}

	static function getDefaultColumns():Array<FlxColor> {
		return switch (Settings.data.noteSkin) {
			case 'camv2': [0xFFE5307F, 0xFF1BC8F1, 0xFF32D844, 0xFFF32931];
			case 'circle': [0xFFDB41B8, 0xFF24D4F7, 0xFF31EB40, 0xFFF32931];
			default: [0xFFC24C99, 0xFF02FFFF, 0xFF13FA06, 0xFFF93A40];
		}
	}

	function scaleNote(note:Note, by:Float) {
		@:privateAccess note.scale.x = note.scale.y = note.styleData.getScale(note) * (by / 0.65);
	}

    override function mouseControl() {
		if (dragging) {
			components[current].hovering(current, list[current], this, mousePoint);
			return;
		}
        if (holdingCol) {
			if (FlxG.mouse.justReleased) {
				holdingCol = false;
				FlxG.sound.play(Paths.audio("scroll", 'sfx'));
			}

            final curItem = current - noteColIdx;
			final max = rgb ? 255 : (current == noteColIdx ? 360 : 100);
			editColor(curItem, Std.int(FlxMath.bound((mousePoint.x - wheels.members[curItem].x) / wheels.members[curItem].width, 0, 1) * max));
			return;
		}

		for (i in 0...(noteSelIdx + 1)) {
            var height = (texts.members[current].height + (hasSubTexts ? (subTexts.members[current].height + 5) * selPercentages[i] : 0));
            if (i == noteSelIdx)
                height = 100;

            var top = texts.members[i].y - 5;

			if (mousePoint.y >= top && mousePoint.y <= top + height && canSelect(i)) {
				retarget((mouseMoved || FlxG.mouse.justPressed) ? i : current);

				components[i].hovering(i, list[i], this, mousePoint);
				if (FlxG.mouse.justPressed && onClick != null)
					onClick(i);
				break;
			}
		}

        if (current == noteSelIdx && mousePoint.y >= hover.y && mousePoint.y <= hover.y + hover.scale.y) {
            var queueHover = -1;
            for (i => note in notes.members) {
                if ((Note.byQuant || i < 4) && mousePoint.x >= note.x && mousePoint.x <= note.x + note.width) {
                    queueHover = i;

                    if (FlxG.mouse.justReleased && curNote != i) {
                        changeNote(i - curNote);
                        FlxG.sound.play(Paths.audio("scroll", 'sfx'));
                    }
                }
            }

            if (queueHover >= 0 && queueHover != hoverNote)
                FlxG.sound.play(Paths.audio("scroll", 'sfx'));
            hoverNote = queueHover;
        } else
            hoverNote = -1;
        
        for (i => wheel in wheels.members) {
            if (mousePoint.x >= wheel.x - 4 && mousePoint.x <= wheel.x + wheel.width + 4 && mousePoint.y >= colTxts.members[i].y && mousePoint.y <= wheel.y + wheel.height) {
                if (mouseMoved && current != noteColIdx + i) {
                    current = noteColIdx + i;
                    FlxG.sound.play(Paths.audio("scroll", 'sfx'));
                }

                if (FlxG.mouse.justPressed) {
                    holdingCol = true;
                    FlxG.sound.play(Paths.audio("scroll", 'sfx'));
                }
            }
        }
    }

    override function position(elapsed:Float) {
		// shhhhh
		for (compon in components) {
			if (compon != null && compon.obj.active)
				compon.update(elapsed);
		}
        notes.update(elapsed);
        bigNote.update(elapsed);

		curScroll = FlxMath.lerp(curScroll, scrollInc * current, elapsed * 15);
        var y = y + 45 - curScroll;
        var targetHeight = 0.0;
        var noteSelY = 0.0;
		for (i in 0...texts.length) {
            var curHeight = 0.0;
            final txt = texts.members[i];
			txt.setPosition(x + 15, y);
			txt.alpha = alpha;
            Util.clipByCoords(txt, null, null, y, y + scale.y);
            
            selPercentages[i] = FlxMath.lerp(selPercentages[i], (i == current ? 1 : 0), elapsed * 15);
			if (hasSubTexts) {
                final sub = subTexts.members[i];
				sub.setPosition(txt.x, txt.y + (txt.height - 5) * selPercentages[i]);
				sub.alpha = alpha * selPercentages[i];
                Util.clipByCoords(sub, null, null, y, y + scale.y);
                
                curHeight += (sub.height + 5) * selPercentages[i];

				components[i].position(txt, sub, selPercentages[i]);
				components[i].clip(y, y + scale.y);
			}

            curHeight += txt.height;
            if (i == noteSelIdx) {
                noteSelY = y;
                curHeight = 100;
            } else if (i > noteSelIdx)
                curHeight = 0;

            if (i == current)
                targetHeight = curHeight;

            y += curHeight;
		}
        scrollInc = Math.max((y + curScroll - this.y - 15 + 60) - height, 0) / texts.length;
        hover.setPosition(x, FlxMath.lerp(hover.y, texts.members[current].y - 5, elapsed * 15));
        hoverHeight = FlxMath.lerp(hoverHeight, targetHeight, elapsed * 15);
		hover.alpha = FlxMath.lerp(hover.alpha, displayHover ? alpha : 0, elapsed * 15);

		hover.scale.y = hoverHeight;
		hover.scale.y -= Math.max((hover.y + hoverHeight) - (y + scale.y), 0);
		var topClip = Math.max(this.y - hover.y, 0);
		hover.y += topClip;
		hover.scale.y -= topClip;
		hover.scale.y = Math.max(hover.scale.y, 0);

        // Note Positioning
        final centerIdx:Float = Note.byQuant ? 5.5 : 2;
		for (i => note in notes.members) {
			note.setPosition(
                FlxMath.lerp(note.x, x + width * 0.5 + 160 * 0.55 * (i - centerIdx), elapsed * 15),
                noteSelY + ((160 * 0.55) - note.height) * 0.5
            );
			scaleNote(note, FlxMath.lerp(note.scale.x / note.styleData.getScale(note) * 0.65, (hoverNote == i || curNote == i) ? 0.65 : 0.55, elapsed * 15));
			note.alpha = FlxMath.lerp(note.alpha, (Note.byQuant || i < 4) ? 1 : 0, elapsed * (7.5 + 7.5 * ((i - 4) / 7)));
		}
        bigNote.y = this.y + 360 + ((160 * 1.5) - bigNote.height) * 0.5;

        for (i in 0...wheels.length) {
            final wheel = wheels.members[i];
            final txt = colTxts.members[i];
			wheel.setPosition(x + 740, this.y + ((i == 0) ? 360 : wheels.members[i - 1].y + wheels.members[i - 1].height + 60));
            txt.setPosition(wheel.x, wheel.y - 5 - txt.height);
            colVals.members[i].setPosition(txt.x, txt.y);
        }
        
        colHover.setPosition(colTxts.members[0].x - 4, FlxMath.lerp(
            colHover.y,
            (current >= noteColIdx && current < noteColIdx + 3) ? colTxts.members[current - noteColIdx].y - 4
                : ((current < noteColIdx) ? colTxts.members[0].y - 20 : wheels.members[2].y + 20),
            elapsed * 15
        ));
        colHover.alpha = FlxMath.lerp(
            colHover.alpha,
            (current >= noteColIdx && current < noteColIdx + 3) ? 1 : 0,
            elapsed * 15
        );
	}

    override function draw() {
        super.draw();

        notes.draw();
        bigNote.draw();
        colHover.draw();

        wheels.draw();
        colHover.blend = INVERT;
        colHover.draw();
        colTxts.draw();
        colVals.draw();
        colHover.draw();
        colHover.blend = NORMAL;
    }
}