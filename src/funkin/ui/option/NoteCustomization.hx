package funkin.ui.option;

import nevermore.play.Note;
import nevermore.skins.NoteskinSection;
import nevermore.Nevermore;

import funkin.shaders.GradMask;
import funkin.shaders.HueGrad;
import funkin.states.OptionsState;
import funkin.core.NoteStyling.NoteskinMeta;

import flixel.graphics.FlxGraphic;
import lime.system.Clipboard;
import lime.ui.FileDialog;

@:access(nevermore.skins.NoteskinSection)
class NoteCustomization extends OptionList {
    var curSection:NoteskinSection<Dynamic>;
    var noteSkinMap:Map<String, NoteskinMeta> = [];
    var notes:FlxTypedGroup<Note>;
	var hoverNote:Int = -1;
	var curNote:Int = 0;
	var bigNote:Note;

	// from experience, setting a color to pitch black can screw up these values.
    var curPalette:Array<flixel.util.FlxColor>;
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

    var actionIdx:Map<String, Int> = [
        "reset" => 0,
        "copy" => 1,
        "paste" => 2,
        "pick" => 3,
        "export" => 4,
        "import" => 5,
        "switch" => 6
    ];
    var curAction:Int = 0;
    var actionsCustom = ["reset", "copy", "paste", "switch", "import", "export"];
    var actionsPreset = ["pick", "copy", "paste", "switch", "export"];
    var keyCountTxt:FlxTypedGroup<FlxText>;
    var actionIcons:FlxTypedGroup<FunkinSprite>;
    var actionHover:FunkinSprite;
    var actionLabel:FlxText;
    var actLabelTimer:FlxTimer = new FlxTimer();

    var paletteDialog:FileDialog;

    var noteSelIdx:Int;
    var noteColIdx:Int;
    var noteActIdx:Int;

    public function new(x:Float, y:Float, width:Float, height:Float) {
        super(x, y, width, height);

        noteSkinMap = NoteStyling.getList();
        if (!noteSkinMap.exists(Settings.data.noteSkin)) {
            for (key in noteSkinMap.keys()) {
                if (key.toLowerCase() == Settings.data.noteSkin.toLowerCase()) {
                    Settings.data.noteSkin = key;
                    break;
                }
            }
        }
        
        var skin = Settings.data.noteSkin;
        var style = Settings.data.noteSkinStyle;

		style = style != "default" && noteSkinMap[skin].styleNames.exists(style) ? style : noteSkinMap[skin].styleKeys[0];

        NoteStyling.updatePalette();
        updatePalette();
        curSection = NoteStyling.getSkinAndStyle(Settings.data.noteSkin, style).sections.get("note");
        notes = new FlxTypedGroup();

		final centerIdx:Float = curPalette.length * 0.5;
        final noteSize:Float = curSection.parent.spacing * 0.85;
		for (i in 0...NoteColor.currentQuants.length) {
			var note = new Note();
            note.data = {snapID: i};
			note.lane = i % NoteColor.current.length;
			note.luminize = Nevermore.settings.luminize;
            note.color = NoteColor.get(note);
            note.scrollFactor.x = 1;

            curSection.applyNoteObject(note);
            note.scale.scale(0.85);
			note.updateHitbox();

			note.setPosition(
                x + FlxG.width * 0.5 + noteSize * 0.85 * (i - centerIdx),
                ((curSection.parent.spacing * 0.85) - note.height) * 0.5
            );

			note.alpha = (NoteColor.bySnap || i < NoteColor.current.length) ? 1 : 0;
			notes.add(note);
		}

		bigNote = new Note();
		bigNote.lane = notes.members[curNote].lane;
		bigNote.luminize = Nevermore.settings.luminize;
		curSection.applyNoteObject(bigNote);
		bigNote.scale.scale(2.25);
		bigNote.updateHitbox();
		bigNote.setPosition(x + 250, y + 370 + ((curSection.parent.spacing * 2.25) - bigNote.height) * 0.5);
		bigNote.color = notes.members[curNote].color;

		colHover = new FunkinSprite();
		colHover.makeGraphic(1, 1, 0xFFFFFFFF);

		var names = ["hue", "saturation", "value"];
		wheels = new FlxTypedGroup<FunkinSprite>();
		colVals = new FlxTypedGroup<FlxText>();
		colTxts = new FlxTypedGroup<FlxText>();
		for (i in 0...3) {
			var wheel = new FunkinSprite(x + 740, (i == 0) ? y + 370 : wheels.members[i - 1].y + wheels.members[i - 1].height + 60);
			wheel.makeGraphic(1, 1, 0xFFFFFFFF);
			wheel.scale.set(390, 35);
			wheel.updateHitbox();
			shaders.push(new GradMask());
			wheel.shader = shaders[shaders.length - 1];
			wheels.add(wheel);

			var txt = new FlxText(wheel.x, wheel.y - 5, wheel.width, getText(names[i]));
			txt.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 20, 0xFFFFFFFF, LEFT);
			txt.y -= txt.height;
			colTxts.add(txt);

			var val = new FlxText(txt.x, txt.y, txt.fieldWidth, Std.string(curCol[i]));
			val.setFormat(Assets.getPath("fonts/LineSeed.ttf"), 20, 0xFFFFFFFF, RIGHT);
			colVals.add(val);
		}

		wheels.members[0].shader = hueShader = new HueGrad();
		updateColor();

		colHover.setPosition(colTxts.members[0].x - 4, colTxts.members[0].y - 4);
		colHover.scale.set(wheels.members[0].width + 8, (wheels.members[0].y + wheels.members[0].height + 4) - (colTxts.members[0].y - 4));
		colHover.origin.set();

        paletteDialog = new FileDialog();
        paletteDialog.onOpen.add(function(bytes) {
            var str:String = cast bytes;
            var type:String = str.substring(0, str.indexOf("\n"));
            if (type != "COLUMNS" && type != "QUANTS") {
                actionFailed("note_pal_invalid", [type]);
                return;
            }
            var bySnap = type == "QUANTS";
            str = str.substring(str.indexOf("\n") + 1);

            var result:Array<FlxColor> = [];
            var lineIdx:Int = str.indexOf("\n");
            var interpResult:Int = 0; // 0 - ok, 1 - skip, 2 - break
            inline function interpLine(line:String) {
                interpResult = (line.trim().length <= 0) ? 1 : 0;

                if (interpResult == 0) {
                    var col = line.trim().replace("#", "0x");
                    if (col.length == 6 && !col.startsWith("0x"))
                        col = "0x" + col;
                    if (col.length != 8) {
                        interpResult = 2;
                        actionFailed("note_pal_bad_type", [line]);
                    } else
                        result.push(Std.parseInt(col));
                }
            }
            while (lineIdx >= 0) {
                var line:String = str.substring(0, lineIdx);
                str = str.substring(lineIdx + 1);
                lineIdx = str.indexOf("\n");
                interpLine(line);
                if (interpResult == 2)
                    return;
            }
            interpLine(str);
            if (interpResult == 2)
                return;

            if (result.length <= 0) {
                actionFailed("note_pal_empty");
                return;
            }
            if (bySnap && result.length != Constants.SNAPS.length) {
                actionFailed("note_pal_quant_mismatch", [Std.string(result.length), Std.string(Constants.SNAPS.length)]);
                return;
            }
            if (!bySnap && result.length != 4) {
                actionFailed("note_pal_no_4k");
                return;
            }

            var target = bySnap ? Settings.data.customQuants : Settings.data.customColumns;
            for (i in 0...result.length)
                target[i] = result[i];
            overrideActionLabel(bySnap ? "note_pal_success_quant" : "note_pal_success_column", [Std.string(result.length)]);

            NoteStyling.updatePalette();
            updatePalette();
            applySection();
            changeNote(0);
        });


        actLabelTimer.finished = true;
        actionHover = new FunkinSprite(x + 5, y + height - 5);
        actionHover.makeGraphic(1, 1, 0xFFFFFFFF);
        actionHover.scale.set(60, 60);
        actionHover.updateHitbox();
        actionHover.y -= actionHover.height;
        actionHover.alpha = 0;

        actionIcons = new FlxTypedGroup();
        keyCountTxt = new FlxTypedGroup();
        regenActions(false);
        /*for (i in 0...9) {
            var key = 9 - i;
            var txt = new FlxText(x + width - 5, y + height - 5, 60, Std.string(key));
            txt.setFormat(Assets.getPath("fonts/cafeSquare.ttf"), 52, (i == curAction - actionIcons.length && current == noteActIdx) ? 0xFF000000 : 0xFFFFFFFF, CENTER);
            txt.fieldHeight = 60;
            txt.x -= txt.width * (i + 1);
            txt.y -= txt.height;
            keyCountTxt.insert(0, txt);
        }*/

        actionLabel = new FlxText(x + 5, actionHover.y);
        actionLabel.setFormat(Assets.getPath("fonts/LineSeedB.ttf"), 20, 0xFFFFFFFF, 0);
        actionLabel.alpha = 0;

        onOptMove = noteOptMove;
        onSelect = (_, __) -> holdingCol = false;
        setOptions([
            {
                var opt = new Option("note_skin", "note_skin_desc", "noteSkin", ListOption([for (skin in noteSkinMap) skin.key], true));
                opt.formatListOption = function(val, _) {
                    return noteSkinMap[val].name ?? val;
                };
                opt.onChange = function(v) {
                    for (i => opt in list) {
                        if (opt.id != "noteSkinStyle") continue;
    
                        var keys = noteSkinMap[v].styleKeys.copy();
                        var names = noteSkinMap[v].styleNames.copy();
                        keys.unshift("default");
                        names.set("default", "Default (By Context)");
    
                        opt.type = ListOption(keys, true);
                        opt.formatListOption = function(item, _) {
                            return names[item] ?? item;
                        };
    
                        if (!noteSkinMap[v].styleNames.exists(Settings.data.noteSkinStyle)) {
                            Settings.data.noteSkinStyle = "default";
                            components[i].change(opt);
                        }
                    }
    
                    var style = Settings.data.noteSkinStyle;
                    style = style != "default" && noteSkinMap[v].styleNames.exists(style) ? style : noteSkinMap[v].styleKeys[0];

                    curSection = NoteStyling.getSkinAndStyle(v, style).sections.get("note");
                    applySection();
    
                    position(0);
                    updatePalette();
                    changeNote(0);
                }
                opt;
            },
            {
                var keys = noteSkinMap[Settings.data.noteSkin].styleKeys.copy();
                var names = noteSkinMap[Settings.data.noteSkin].styleNames.copy();
                keys.unshift("default");
                names.set("default", "Default (By Context)");
    
                var opt = new Option("note_skin_style", "note_skin_style_desc", "noteSkinStyle", ListOption(keys, true));
                opt.formatListOption = function(item, _) {
                    return names[item] ?? item;
                };
                opt.onChange = function(v) {
                    var skin = Settings.data.noteSkin;
                    v = v != "default" && noteSkinMap[skin].styleNames.exists(v) ? v : noteSkinMap[skin].styleKeys[0];

                    curSection = NoteStyling.getSkinAndStyle(Settings.data.noteSkin, v).sections.get("note");
                    applySection();
    
                    position(0);
                    updatePalette();
                    changeNote(0);
                }
                opt;
            },
            /*
            *yawwwwwwwwwwwwwnnnnnnnn later
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
            },*/
            { // this can be reverted if the order of the quants matter
                var quantPalettes: Array<String> = [];
                for(name in NoteColor.quantList.keys())
                    quantPalettes.push(name);
                quantPalettes.remove("Custom");
    
                quantPalettes.unshift('Custom (Columns)');
                quantPalettes.unshift('Custom');
                quantPalettes.unshift('None');
    
                var opt = new Option('quant_coloring', 'quant_coloring_desc', "quantColouring", ListOption(quantPalettes, true));
                opt.onChange = function(v) {
                    NoteStyling.updatePalette();
                    updatePalette();

                    applySection();
                    
                    regenActions();
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
                var opt = new Option("<NO-LANG> ", "<NO-LANG> ", "NOTE_ACTIONS", ButtonOption);
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
        FlxG.sound.play(Assets.audio("sfx/scroll"));
        switch (list[current].id) {
            case "NOTE_SELECT":
                changeNote(inc);
            case "NOTE_EDIT_COL_0":
                editColor(0, Std.int(FlxMath.bound(curCol[0] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, rgb ? 255 : 360)));
            case "NOTE_EDIT_COL_1":
                editColor(1, Std.int(FlxMath.bound(curCol[1] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, rgb ? 255 : 100)));
            case "NOTE_EDIT_COL_2":
                editColor(2, Std.int(FlxMath.bound(curCol[2] + inc * (FlxG.keys.pressed.SHIFT ? 1 : 5), 0, rgb ? 255 : 100)));
            case "NOTE_ACTIONS":
                FlxG.sound.play(Assets.audio("sfx/scroll"));
                changeAction(inc);
        }
    }

	function updateColor() {
		if (rgb) {
			curCol[0] = curPalette[curNote].red;
			curCol[1] = curPalette[curNote].green;
			curCol[2] = curPalette[curNote].blue;

			for (i in 0...shaders.length) {
				shaders[i].fromCol.value = [(i == 0 ? 0 : curCol[0] / 255), (i == 1 ? 0 : curCol[1] / 255), (i == 2 ? 0 : curCol[2] / 255), 1];
				shaders[i].toCol.value = [(i == 0 ? 1 : curCol[0] / 255), (i == 1 ? 1 : curCol[1] / 255), (i == 2 ? 1 : curCol[2] / 255), 1];
			}

			for (i => val in colVals)
				val.text = Std.string(curCol[i]);

			return;
		}

		if (curPalette[curNote].rgb == 0x000000) {
			curCol[0] = 0;
			curCol[1] = 100;
			curCol[2] = 0;
		} else {
			curCol[0] = Math.floor(curPalette[curNote].hue);
			curCol[1] = Math.floor(curPalette[curNote].saturation * 100);
			curCol[2] = Math.floor(curPalette[curNote].brightness * 100);
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

    function updatePalette() {
        if (!Nevermore.settings.luminize)
            curPalette = (noteSkinMap[Settings.data.noteSkin].colors[/*keyCount - 1*/ 3]).copy();
        else
            curPalette = (NoteColor.bySnap ? NoteColor.currentQuants : NoteColor.current).copy();
    }
    function applySection() {
        for (note in notes) {
            note.luminize = Nevermore.settings.luminize;
            note.color = NoteColor.get(note);
            curSection.applyNoteObject(note);
            note.scale.scale(0.85);
            note.updateHitbox();
        }

        bigNote.color = notes.members[curNote].color;
        bigNote.luminize = Nevermore.settings.luminize;
        curSection.applyNoteObject(bigNote);
        bigNote.scale.scale(2.25);
        bigNote.updateHitbox();
        bigNote.y = y + 370 + ((curSection.parent.spacing * 2.25) - bigNote.height) * 0.5;
    }
	function changeNote(inc:Int) {
		curNote = FlxMath.wrap(curNote + inc, 0, (NoteColor.bySnap ? NoteColor.currentQuants.length : NoteColor.current.length) - 1);

        bigNote.luminize = Nevermore.settings.luminize;
        bigNote.color = notes.members[curNote].color;
        bigNote.lane = notes.members[curNote].lane;
        curSection.applyNoteObject(bigNote);

        bigNote.scale.scale(2.25);
        bigNote.updateHitbox();
        bigNote.y = y + 370 + ((curSection.parent.spacing * 2.25) - bigNote.height) * 0.5;

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

		notes.members[curNote].luminize = bigNote.luminize = true;
		if (rgb) {
			notes.members[curNote].color = bigNote.color = curPalette[curNote] = FlxColor.fromRGB(curCol[0], curCol[1], curCol[2]);
			checkCanApply();

			for (i in 0...shaders.length) {
				if (i == idx) continue;
				shaders[i].fromCol.value = [(i == 0 ? 0 : curCol[0] / 255), (i == 1 ? 0 : curCol[1] / 255), (i == 2 ? 0 : curCol[2] / 255), 1];
				shaders[i].toCol.value = [(i == 0 ? 1 : curCol[0] / 255), (i == 1 ? 1 : curCol[1] / 255), (i == 2 ? 1 : curCol[2] / 255), 1];
			}

			return;
		}

		notes.members[curNote].color = bigNote.color = curPalette[curNote] = FlxColor.fromHSB(curCol[0], curCol[1] * 0.01, curCol[2] * 0.01);
		checkCanApply();
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
        if (Settings.data.quantColouring.startsWith("Custom")) {
            if (NoteColor.bySnap)
                Settings.data.customQuants = curPalette;
            else
                Settings.data.customColumns = curPalette;
        }

		/*final isCustom = Settings.data.quantColouring.startsWith("Custom");
		final data = isCustom ? Settings.default_data : Settings.data;
		//actionTxt.members[0].visible = curPalette[curNote] != (NoteColor.bySnap ? data.customQuants : data.customColumns)[curNote];

        var skinPalette = noteSkinMap[Settings.data.noteSkin].colors[3]; // [keyCount - 1]
		colWarning.visible = !isCustom && curPalette[curNote] != (NoteColor.bySnap ? NoteColor.quantList[Settings.data.quantColouring] : skinPalette)[curNote];*/
	}

    function overrideActionLabel(with:String, ?args:Array<String>) {
        actionLabel.text = getFormattedText(with, args ?? []);
        actLabelTimer.start(1, function(_) {
            if (current != noteActIdx)
                return;

            var actionArray = Settings.data.quantColouring.startsWith("Custom") ? actionsCustom : actionsPreset;
            actionLabel.text = curAction >= actionArray.length ? getFormattedText("note_switch_key", [Std.string(curAction - actionArray.length + 1)]) : getText("note_" + actionArray[curAction]);
        });
    }
    function actionFailed(reason:String, ?args:Array<String>) {
        args ??= [];
        Sys.println(getFormattedText(reason, args));
        overrideActionLabel(reason, args);
        FlxG.sound.play(Assets.audio("sfx/cancel"));

        FlxTween.cancelTweensOf(actionHover);
        FlxTween.shake(actionHover, 5 / actionHover.scale.x, 0.35, X, {ease: FlxEase.quadOut});
        FlxTween.color(actionHover, 0.35, 0xFFFF5F5F, 0xFFFFFFFF, {ease: FlxEase.quadOut});
    }
    function runAction(idx:Int) {
        if (idx >= actionIcons.length) {
            // nothing for now
            return;
        }

        var actionArray = Settings.data.quantColouring.startsWith("Custom") ? actionsCustom : actionsPreset;
        switch (actionArray[idx]) {
            case "reset":
                FlxG.sound.play(Assets.audio("sfx/scroll"));
                var target = NoteColor.bySnap ? Settings.data.customQuants : Settings.data.customColumns;
                var ref = NoteColor.bySnap ? Settings.default_data.customQuants : Settings.default_data.customColumns;
                bigNote.color = notes.members[curNote].color = target[curNote] = curPalette[curNote] = ref[curNote];
                updateColor();
            case "copy":
				FlxG.sound.play(Assets.audio("sfx/scroll"));
				Clipboard.text = curPalette[curNote].toWebString();
			case "paste":
				var str = Clipboard.text.replace("#", "0x");
				if (str.length == 6 && !str.startsWith("0x"))
					str = "0x" + str;

				if (str.length == 8) {
					FlxG.sound.play(Assets.audio("sfx/scroll"));
					notes.members[curNote].color = bigNote.color = curPalette[curNote] = Std.parseInt(str);
					updateColor();
					checkCanApply();
				} else
                    actionFailed("note_bad_paste", [Clipboard.text]);
            case "pick":
                FlxG.sound.play(Assets.audio("sfx/scroll"));
                var target = NoteColor.bySnap ? Settings.data.customQuants : Settings.data.customColumns;
                target[curNote] = curPalette[curNote];
            case "import":
                paletteDialog.open("txt");
            case "export":
                var result = NoteColor.bySnap ? "QUANTS" : "COLUMNS";
                for (col in curPalette)
                    result += "\n" + col.toWebString();
                paletteDialog.save(result, "txt");
            case "switch":
                FlxG.sound.play(Assets.audio("sfx/scroll"));
                rgb = !rgb;
                wheels.members[0].shader = rgb ? shaders[0] : hueShader;
                updateColor();
        
                var names = rgb ? ["red", "green", "blue"] : ["hue", "sat", "val"];
                for (i in 0...colTxts.length)
                    colTxts.members[i].text = getText(names[i]);
        }
    }
    function changeAction(inc:Int) {
        var actionArray = Settings.data.quantColouring.startsWith("Custom") ? actionsCustom : actionsPreset;
        curAction = FlxMath.wrap(curAction + inc, 0, actionArray.length - 1 + keyCountTxt.length);
        if (actLabelTimer.finished) {
            actionLabel.text = curAction >= actionArray.length ? getFormattedText("note_switch_key", [Std.string(curAction - actionArray.length + 1)]) : getText("note_" + actionArray[curAction]);
            actionLabel.y = actionHover.y;
            actionLabel.alpha = 0;
        }
        actionLabel.x = curAction >= actionArray.length ? x + width - 5 - actionLabel.width : x + 5;
    }
    function regenActions(?fixIndex:Bool = true) {
        var actionArray = Settings.data.quantColouring.startsWith("Custom") ? actionsCustom : actionsPreset;
        if (fixIndex)
           curAction = curAction >= actionIcons.length ? (curAction - actionIcons.length) + actionArray.length : FlxMath.minInt(curAction, actionArray.length - 1);

        while (actionIcons.length > actionArray.length) {
            var ico = actionIcons.members[actionIcons.length - 1];
            actionIcons.remove(ico, true);
            ico.destroy();
        }
        for (i in 0...actionArray.length) {
            if (i >= actionIcons.length)
                makeActionIcon(actionArray[i]);
            else
                actionIcons.members[i].animation.play(actionArray[i]);
        }
    }
    function makeActionIcon(act:String) {
        var actTex = Assets.image("images/menus/options/notesactionsgay");

        var icon = new FunkinSprite(x + 5 + 60 * actionIcons.length, y + height - 5);
        icon.loadGraphic(actTex, true, actTex.height, actTex.height);
        for (k => idx in actionIdx)
            icon.animation.add(k, [idx]);
        icon.animation.play(act);
        icon.color = actionIcons.length == curAction && current == noteActIdx ? 0xFF000000 : 0xFFFFFFFF;
        icon.y -= icon.height;
        actionIcons.add(icon);
    }

    override function mouseControl() {
		if (dragging) {
			components[current].hovering(current, list[current], this, mousePoint);
			return;
		}
        if (holdingCol) {
			if (FlxG.mouse.justReleased) {
				holdingCol = false;
				FlxG.sound.play(Assets.audio("sfx/scroll"));
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
                if ((NoteColor.bySnap || i < NoteColor.current.length) && mousePoint.x >= note.x && mousePoint.x <= note.x + note.width) {
                    queueHover = i;

                    if (FlxG.mouse.justReleased && curNote != i) {
                        changeNote(i - curNote);
                        FlxG.sound.play(Assets.audio("sfx/scroll"));
                    }
                }
            }

            if (queueHover >= 0 && queueHover != hoverNote)
                FlxG.sound.play(Assets.audio("sfx/scroll"));
            hoverNote = queueHover;
        } else
            hoverNote = -1;
        
        for (i => wheel in wheels.members) {
            if (mousePoint.x >= wheel.x - 4 && mousePoint.x <= wheel.x + wheel.width + 4 && mousePoint.y >= colTxts.members[i].y && mousePoint.y <= wheel.y + wheel.height) {
                if (mouseMoved && current != noteColIdx + i) {
                    current = noteColIdx + i;
                    FlxG.sound.play(Assets.audio("sfx/scroll"));
                }

                if (FlxG.mouse.justPressed) {
                    holdingCol = true;
                    FlxG.sound.play(Assets.audio("sfx/scroll"));
                }
            }
        }

        for (i => icon in actionIcons.members) {
            if (!(mousePoint.x >= icon.x && mousePoint.x <= icon.x + icon.width && mousePoint.y >= icon.y && mousePoint.y <= icon.y + icon.height))
                continue;

            if (mouseMoved && (curAction != i || current != noteActIdx)) {
                FlxG.sound.play(Assets.audio("sfx/scroll"));
                current = noteActIdx;
                changeAction(i - curAction);
            }
            if (FlxG.mouse.justPressed) {
                runAction(i);
            }
        }
        for (i => txt in keyCountTxt.members) {
            if (!(mousePoint.x >= txt.x && mousePoint.x <= txt.x + txt.width && mousePoint.y >= txt.y && mousePoint.y <= txt.y + txt.height))
                continue;

            if (mouseMoved && (curAction != i + actionIcons.length || current != noteActIdx)) {
                FlxG.sound.play(Assets.audio("sfx/scroll"));
                current = noteActIdx;
                changeAction((i + actionIcons.length) - curAction);
            }
            if (FlxG.mouse.justPressed)
                runAction(i + actionIcons.length);
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

        alpha = FlxMath.lerp(alpha, focused ? 1 : 0.5, elapsed * 15);
		curScroll = FlxMath.lerp(curScroll, scrollInc * current, elapsed * 15);
        var colorMult = Math.max(2 * alpha - 1, 0);
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
            txt.color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercentages[i] * colorMult);
			if (hasSubTexts) {
                final sub = subTexts.members[i];
				sub.setPosition(txt.x, txt.y + (txt.height - 5) * selPercentages[i]);
				sub.alpha = alpha * selPercentages[i];
                sub.color = txt.color;
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
		hover.alpha = FlxMath.lerp(hover.alpha, focused ? alpha : 0, elapsed * 15);

		hover.scale.y = hoverHeight;
		hover.scale.y -= Math.max((hover.y + hoverHeight) - (y + scale.y), 0);
		var topClip = Math.max(this.y - hover.y, 0);
		hover.y += topClip;
		hover.scale.y -= topClip;
		hover.scale.y = Math.max(hover.scale.y, 0);

        // Note Positioning
        final centerIdx:Float = curPalette.length * 0.5;
        final noteSize:Float = curSection.parent.spacing * 0.85;
		for (i => note in notes.members) {
			note.setPosition(
                FlxMath.lerp(note.x, x + width * 0.5 + noteSize * (i - centerIdx), elapsed * 15),
                noteSelY + (noteSize - note.height) * 0.5
            );
            note.scale.x = note.scale.y = FlxMath.lerp(note.scale.x, curSection.scale * (hoverNote == i || curNote == i ? 1 : 0.85), elapsed * 15);

            var alphaLerpRatio = elapsed * (7.5 + 7.5 * ((i - NoteColor.current.length) / 7));
			note.alpha = FlxMath.lerp(note.alpha, (NoteColor.bySnap || i < NoteColor.current.length) ? 1 : 0, alphaLerpRatio);
        }
        bigNote.y = this.y + 360 + ((curSection.parent.spacing * 2.25) - bigNote.height) * 0.5;

        for (i in 0...wheels.length) {
            final wheel = wheels.members[i];
            final txt = colTxts.members[i];
			wheel.setPosition(x + 740, this.y + ((i == 0) ? 360 : wheels.members[i - 1].y + wheels.members[i - 1].height + 60));
            txt.setPosition(wheel.x, wheel.y - 5 - txt.height);

            txt.color = FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, selPercentages[i + noteColIdx]);
            colVals.members[i].color = txt.color;
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

        actionHover.x = FlxMath.lerp(actionHover.x, curAction >= actionIcons.length ? keyCountTxt.members[curAction - actionIcons.length].x : actionIcons.members[curAction].x, elapsed * 15);
        actionHover.alpha = FlxMath.lerp(actionHover.alpha, current == noteActIdx ? 1 : 0, elapsed * 15);
        actionLabel.alpha = FlxMath.lerp(actionLabel.alpha, current == noteActIdx || !actLabelTimer.finished ? 1 : 0, elapsed * 10);
        actionLabel.y = actionHover.y - actionLabel.height * actionLabel.alpha;
        for (i in 0...actionIcons.length)
            actionIcons.members[i].color = FlxColor.interpolate(actionIcons.members[i].color, (i == curAction && current == noteActIdx) ? 0xFF000000 : 0xFFFFFFFF, elapsed * 15);
        for (i in 0...keyCountTxt.length)
            keyCountTxt.members[i].color = FlxColor.interpolate(keyCountTxt.members[i].color, (i == curAction - actionIcons.length && current == noteActIdx) ? 0xFF000000 : 0xFFFFFFFF, elapsed * 15);
	}

    override function destroy() {
        super.destroy();

        notes.destroy();
        bigNote.destroy();
        colHover.destroy();

        wheels.destroy();
        colTxts.destroy();
        colVals.destroy();
    }

    override function draw() {
        super.draw();

        notes.draw();
        bigNote.draw();
        colHover.draw();

        wheels.draw();
        // colHover.blend = INVERT;
        // colHover.draw();
        colTxts.draw();
        colVals.draw();
        // colHover.draw();
        // colHover.blend = NORMAL;

        actionLabel.draw();
        actionHover.draw();
        actionIcons.draw();
        keyCountTxt.draw();
    }
}