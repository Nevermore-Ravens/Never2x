package funkin.states;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import funkin.backend.Song.Chart;
import funkin.objects.*;
import funkin.backend.EventHandler;
import funkin.objects.Strumline.StrumNote;
//import funkin.Dialogue;

@:structInit class NoteHit {
	public var time:Float;
	public var diff:Float;
	public var color:FlxColor;
	public var countMean:Bool = true;
}

class PlayState extends FunkinState {
	public static var songID:String = 'tremendous';
	public var songName:String = '';
	public static var song:Chart;
	public static var self:PlayState;
	public static var weekData:WeekFile;
	public static var deaths:Int = 0;

	public static var inTransition:Bool = false;
	public static var songList:Array<String> = [];
	public static var storyMode:Bool = false;

	public static var currentLevel:Int = 0;
	public var paused:Bool = false;
	public var canPause:Bool = true;
	var extraTime:Float = 2500;
	var allowStartup:Bool = true;
	var skipStrumFade:Bool = false;
	var canMoveCamera:Bool = false;

	var noteSkin:String;

	public var noteHitList:Array<NoteHit> = [];
	public var score:Int = 0;
	var metronome:Bool = false;
	public var comboBreaks:Int = 0;
	var combo:Int = 0;
	public var accuracy:Float = 0.0;
	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		if ((playfield.playerID == 1 && value <= 0) || (playfield.playerID == 0 && value >= 100))
			death();
		value = FlxMath.bound(value, 0, 100);

		// update health bar
		health = value;
		healthBar.updatePercent();
		updateIconStates();
		updateIconPositions();

		return health = value;
	}

	@:unreflective var disqualified:Bool = false;

	@:isVar public var botplay(get, set):Bool = false;
	function get_botplay():Bool {
		if (playfield == null) return false;
		// preventing someone doing `game.playfield.botplay = true;`
		// to get around disqualifying
		if (playfield.botplay) disqualified = true;
		return playfield.botplay;
	}

	function set_botplay(value:Bool):Bool {
		// prevents players from just having botplay on the entire time
		// and then turning it off at the last note
		// and saving the play
		if (value) disqualified = true;

		playfield.botplay = value;
		botplayTxt.visible = value;
		return botplay = value;
	}

	// 1 instead of 0
	// because we're in an fnf based state
	// not just funny base rhythm game class
	// (1 = bf, 0 = dad)
	@:isVar public var playerID(get, set):Int = 1;
	function get_playerID():Int {
		if (playfield == null) return 1;
		return playfield.playerID;
	}

	function set_playerID(v:Int):Int {
		if (playfield == null) return playerID = v;

		return playfield.playerID = v;
	}

	var clearType:String;

	public var totalNotes:Int;
	public var notesHit:Int = 0;
	public var notesPlayed:Float = 0.0;

	static var storyScore:Int = 0;

	var gfSpeed:Int = 1;
	var cameraSpeed:Float = 0.1;

	public var playfield:PlayField;
	public var playerStrums:Strumline;
	public var opponentStrums:Strumline;
	var characterCache:Map<String, Character> = [];

	var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;

	var eventHandler:EventHandler;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var ranking:FlxText;
	var judgeFormats:Array<FlxTextFormat> = [];
	var judgeNames:FlxText;
	var judgeCounter:FlxText;
	var timingIndicator:FlxText;

	var hud:FlxSpriteGroup;

	var noteCamOffset:Array<FlxPoint> = [
		FlxPoint.get(-10, 0),
		FlxPoint.get(0, 10),
		FlxPoint.get(0, -10),
		FlxPoint.get(10, 0)
	];
	var noteCamDelay:Float = 0;

	var timeText:FlxText;
	var infoText:FlxText;
	var healthBar:Bar;

	var iconP1:CharIcon;
	var iconP2:CharIcon;

	var downscroll:Bool = false;

	var botplayTxt:FunkinSprite;
	var stageName:String;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	var hitErrorBar:HitErrorBar;

	var camFollow:FlxObject;

	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

	public var stage:Stage;

	final iconSpacing:Float = 30;
	public var defaultCamZoom:Float = 1;
	public var defaultHudZoom:Float = 1;
	public var isZooming:Bool = false;

	override function create():Void {
		super.create();
		Conductor.stop();
		FlxG.timeScale = Settings.data.gameplayModifiers["playbackRate"];

		self = this;
/*		if (storyMode) {
			songID = songList[currentLevel];
			StoryMenuState.fromPlayState = true;
		} else
			FreeplayState.fromPlayState = true;
		OptionsState.inPlayState = false;*/

		clearType = updateClearType();
		FlxG.mouse.visible = false;
		downscroll = Settings.data.downscroll;
		metronome = Settings.data.metronome;
		noteSkin = Settings.data.noteSkin;
		var strumlineYPos:Float = downscroll ? FlxG.height - 50 - Strumline.swagWidth : 50; // i mean the new position is only 4 pixels off so

		FlxG.cameras.reset(camGame = new FlxCamera());
		camGame.bgColor.alpha = 0;

		add(camFollow = new FlxObject());
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		camGame.follow(camFollow, LOCKON, 0.5);

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.gameVisibility / 100);

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.gameVisibility <= 0) {
			camGame.visible = false;
			camGame.active = false;
			camHUD.bgColor = FlxColor.TRANSPARENT;
		}

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		ScriptHandler.loadFromDir('scripts');

		Conductor._time = -(extraTime * FlxG.timeScale);
		Conductor.rawTime = Conductor.time = Conductor._time + Conductor.offset;

		playerStrums = new Strumline(960, strumlineYPos - 10, true, noteSkin);
		opponentStrums = new Strumline(320, strumlineYPos - 10, false, noteSkin);

		var extraStrumline:Strumline = new Strumline(0, strumlineYPos - 10, false, Settings.data.noteSkin);
		extraStrumline.screenCenter(X);
		extraStrumline.visible = false;

		var strumlines = [opponentStrums, playerStrums, extraStrumline];
		var playerID = switch (Settings.data.gameplayModifiers['playingSide']) {
			case 'Default': // BF/RIGHT SIDE/PLAYER/ETC
				1;

			case 'Opponent': // DAD/LEFT SIDE/ETC
				0;

			case 'Dancer': // GF/WHATEVER THE FUCK
				// if dancer doesn't have a chart for the song just default to the player side
				if (!Song.exists(songID, 'gf')) {
					Settings.data.gameplayModifiers['playingSide'] = 'Default';
					1;
				} else 2;

			case _: // defaults to 'Default' (no shit
				1;
		}
		var popupX:Float = (!Settings.data.centeredNotes && Settings.data.popupCenter == "Field") ? strumlines[playerID].centerX : FlxG.width * 0.5;

		add(judgeSpr = new JudgementSpr(popupX, downscroll ? FlxG.height - 175 : 40));
		judgeSpr.cameras = [camHUD];
		judgeSpr.x -= judgeSpr.width * 0.5;

		add(comboNumbers = new ComboNums(popupX, downscroll ? FlxG.height - 50 : 165));
		comboNumbers.cameras = [camHUD];
		comboNumbers.x -= comboNumbers.width * 0.5;

		if (Settings.data.centeredNotes || Settings.data.popupCenter != "Top") {
			judgeSpr.screenCenter(Y);
			comboNumbers.y = judgeSpr.y + 125;
		}

		add(playfield = new PlayField(strumlines));
		playfield.cameras = [camHUD]; // so you can still `game.hud.visible = false;` without hiding the strumlines too
		playfield.scrollSpeed = Settings.data.scrollSpeed;
		playfield.downscroll = downscroll;
		playfield.playerID = playerID;

		playfield.noteHit = noteHit;
		playfield.sustainHit = sustainHit;
		playfield.noteMiss = noteMiss;
		playfield.ghostTap = ghostTap;
		playfield.noteSpawned = noteSpawned;

		playfield.add(noteSplashes = new FlxTypedSpriteGroup<NoteSplash>());
		playfield.noteSplashes = noteSplashes;
		for (i in 0...Strumline.keyCount) noteSplashes.add(new NoteSplash(i));
		noteSplashes.cameras = [camHUD];

		add(hud = new FlxSpriteGroup());
		hud.visible = !Settings.data.hideHUD;
		hud.cameras = [camHUD];

		if (Settings.data.centeredNotes) {
			for (i => line in playfield.strumlines.members) {
				if (i == playfield.playerID) {
					line.screenCenter(X);
					continue;
				}

				line.visible = false;
				line.alpha = 0;
			}
		} else if (!Settings.data.opponentNotes) {
			for (i => line in playfield.strumlines.members)
				line.visible = i == playfield.playerID;
		}

		if (Settings.data.gameplayModifiers['blind']) {
			playerStrums.visible = false;
			opponentStrums.visible = false;
		}

		loadSong();

		eventHandler = new EventHandler();
		eventHandler.triggered = eventTriggered;
		eventHandler.pushed = eventPushed;
		eventHandler.load(songID, song);

		stage = new Stage(stageName);
		ScriptHandler.loadFile(Paths.get('stages/$stageName.hx'));
		camGame.zoom = defaultCamZoom = stage.zoom;
		camFollow.setPosition(stage.camera.x, stage.camera.y);
		canMoveCamera = stage.canMoveCamera;
		camGame.snapToTarget();

		add(gf = new Character(stage.spectator.x, stage.spectator.y, song.meta.spectator, stage.reflective));
		gf.visible = stage.isSpectatorVisible;
		ScriptHandler.loadFile(Paths.get('characters/${gf.name}.hx'));
		extraStrumline.character = function() return gf;

		//to-do add to the json the character positions and position of it's reflections
		add(dad = new Character(stage.opponent.x, stage.opponent.y, song.meta.enemy, stage.reflective));
		ScriptHandler.loadFile(Paths.get('characters/${dad.name}.hx'));
		add(bf = new Character(stage.player.x, stage.player.y, song.meta.player, stage.reflective));
		ScriptHandler.loadFile(Paths.get('characters/${bf.name}.hx'));

		playerStrums.character = function() return bf;
		opponentStrums.character = function() return dad;
		opponentStrums.healthMult = -1.0;

		loadHUD();

		Conductor.syncBeats();
		ScriptHandler.call('create');

		if (#if MODCHARTS_ALLOWED playfield.modchart == null && #end Settings.data.laneUnderlay > 0) {
			var playerLaneUnderlay = new FunkinSprite(playerStrums.x).makeGraphic(1, 1, FlxColor.BLACK);
			playerLaneUnderlay.scale.set(playerStrums.width + 20, FlxG.height);
			playerLaneUnderlay.updateHitbox();
			playerLaneUnderlay.x += ((playerStrums.width - playerLaneUnderlay.scale.x) / 2);
			playerLaneUnderlay.alpha = Settings.data.laneUnderlay;
			playerLaneUnderlay.camera = camHUD;
			playerLaneUnderlay.visible = playerStrums.visible;
			insert(members.indexOf(playfield) - 2, playerLaneUnderlay);

			var opponentLaneUnderlay = new FunkinSprite(opponentStrums.x).makeGraphic(1, 1, FlxColor.BLACK);
			opponentLaneUnderlay.scale.set(opponentStrums.width + 20, FlxG.height);
			opponentLaneUnderlay.updateHitbox();
			opponentLaneUnderlay.x += ((opponentStrums.width - opponentLaneUnderlay.scale.x) / 2);
			opponentLaneUnderlay.alpha = Settings.data.laneUnderlay;
			opponentLaneUnderlay.camera = camHUD;
			opponentLaneUnderlay.visible = opponentStrums.visible;
			insert(members.indexOf(playfield) - 2, opponentLaneUnderlay);
		}

		var dontStart = (Dialogue.fileExists(songID) && storyMode);
		if (dontStart) {
			var dialogue:Dialogue = new Dialogue(songID);
			dialogue.cameras = [camOther];
			openSubState(dialogue);
			dialogue.onClose = start.bind(false);
		}

		fadeStrums();

		botplay = Settings.data.gameplayModifiers["botplay"];
		disqualified = disqualified || (Settings.data.gameplayModifiers["randomizedNotes"] || !Settings.data.gameplayModifiers["sustains"]);

	 	if (!dontStart) start();

		DiscordClient.changePresence('Playing: $songName', '', '', true);

		//Dialogue.fromMenu = false;
	}

	function start(?skipTimer:Bool = false) {
		if (!allowStartup) return;

		if (skipTimer) {
			Conductor.play();
			ScriptHandler.call('songStarted');
			return;
		}
		
		Conductor.playing = true;
		new FlxTimer().start((extraTime * FlxG.timeScale) / 1000, _ -> {
			Conductor.play();
			ScriptHandler.call('songStarted');
		});
	}

	function fadeStrums() {
		if (skipStrumFade) {
			playfield.strumlines.alpha = 1;
			return;
		}

		var strumFadeTime:Float = 0.5;

		for (strumline in playfield.strumlines) {
			for (i => strum in strumline.members) {
				strum.alpha = 0;
				Main.tweenManager.tween(strum, {y: strum.y + 10, alpha: strumline.alpha}, strumFadeTime, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
		}
	}

	function eventTriggered(event:Event):Void {
		ScriptHandler.call('eventTriggered', [event.name, event.args, event.time]);

		switch event.name {
			case 'Change Character':
				var type:Int = event.args[0];
				var character:Character = switch type {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				var name:String = event.args[1];
				if (character == null || character.name == name) return;
				changeCharacter(type, name);

			case 'Hey!':
				var character:Character = switch event.args[0] {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				if (character == null || !character.animation.exists('cheer')) return;
				character.playAnim('cheer', true);
				character.specialAnim = true;

			case 'Retarget Camera':
				if (!canMoveCamera) return;

				var who:Int = event.args[0];
				moveCamera(playfield.getStrumline(who).character());
		}
	}

	// stealing from myself Lol Lmao -rudy
	function moveCamera(character:Character) {
		if (character == null) return;

		camFollow.setPosition(character.getMidpoint().x, character.getMidpoint().y);
		camFollow.x += character.cameraOffset.x;
		camFollow.y += character.cameraOffset.y;
	}

	var eventList:Array<String> = [];
	function eventPushed(event:Event):Void {
		eventPushedUnique(event);
		if (eventList.contains(event.name)) return;

		ScriptHandler.call('eventPushed', [event]);
		eventList.push(event.name);
	}

	function eventPushedUnique(event:Event):Void {
		ScriptHandler.call('eventPushedUnique', [event]);

		switch event.name {
			case 'Change Character':
				cacheCharacter(event.args[1]);
		}
	}

	function cacheCharacter(name:String):Character {
		var character:Character = new Character(0, 0, name);
		character.alpha = 0.0001;
		character.draw();
		character.visible = false;
		character.active = false;
		add(character);
		characterCache.set(name, character);
		return character;
	}

	function changeCharacter(type:Int, name:String) {
		var newCharacter:Character = characterCache[name] ?? new Character(0, 0, name);

		var character:Character = switch type {
			case 0: dad;
			case 1: gf;
			case 2: bf;

			default: null;
		}

		// make sure it layers properly
		remove(newCharacter);
		insert(members.indexOf(character), newCharacter);

		newCharacter.alpha = character.alpha;
		newCharacter.visible = character.visible;
		newCharacter.active = character.active;
		newCharacter.reflective = character.reflective;
		newCharacter.setPosition(character.x, character.y);
		character.visible = false;
		character.active = false;

		if (type == 0) {
			dad = newCharacter;
			iconP2.change(newCharacter.icon);
		} else if (type == 1) gf = newCharacter;
		else if (type == 2) {
			bf = newCharacter;
			iconP1.change(newCharacter.icon);
		}

		healthBar.setColors(dad.healthColor, bf.healthColor);
		updateIconStates();
	}

	function noteSpawned(note:Note):Void {
		ScriptHandler.call('noteSpawned', [note]);
	}

	// for stages
	function addBehindObject(obj:FlxBasic, target:FlxBasic) {
		return insert(members.indexOf(target), obj);
	}

	var botplayTxtSine:Float = 0;
	override function update(delta:Float):Void {
		super.update(delta);

		updateCameraScale(delta);
		updateIconScales(delta);
		updateIconPositions();
		if (Conductor.rawTime > 0)
			updateTimeText();

		if (Settings.data.notesMoveCamera) {
			if (noteCamDelay > 0) noteCamDelay -= delta;
			else camGame.targetOffset.set();
		}

		if (Conductor.rawTime >= 0) eventHandler.update();

		if (FlxG.keys.justPressed.F8) botplay = !botplay;

		if (botplayTxt.visible) {
			botplayTxtSine += 180 * delta;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplayTxtSine) / 180);
		}

		if (Controls.justPressed('reset') && Settings.data.canReset && !alreadyDying) {
			death();
		}

		if (Controls.justPressed('pause') && canPause) {
			final substate:PauseMenu = new PauseMenu(songName, Difficulty.current, deaths);
			substate.cameras = [camOther];
			paused = true;

			openSubState(substate);
		}

		camGame.followLerp = !paused ? (cameraSpeed * FlxG.timeScale) : 0;
		ScriptHandler.call('update', [delta]);
	}

	inline function singCharacter(strumline:Strumline, note:Note) {
		var curCharacter:Character = strumline.character();
		if (note.type == 'GF Sing') curCharacter = gf;
		var dontAnimate:Bool = note.noAnimation && note.type != 'GF Sing';
		if (curCharacter == null) return;

		if (note.type == 'Cheer') {
			curCharacter.playAnim('cheer');
			curCharacter.specialAnim = true;
		}

		if (dontAnimate) return;

		curCharacter.playAnim('sing${Note.directions[note.lane].toUpperCase()}', true, note.animSuffix);
	}

	function noteHit(strumline:Strumline, note:Note) {
		note.wasHit = true;

		if(ScriptHandler.call('noteHit', [strumline, note]) == -1)return;

		singCharacter(strumline, note);

		if (note.player != playerID) {
			note.hitJudgement = Judgement.list[1];
			if (note.sustain != null)
				note.sustain.hitJudgement = note.hitJudgement;
			return;
		} else if (botplay) {
			if (Settings.data.notesMoveCamera) {
				noteCamDelay = 0.5;
				var offsetToUse:FlxPoint = noteCamOffset[note.lane];
				camGame.targetOffset.set(offsetToUse.x, offsetToUse.y);
			}

			final judge:Judgement = Judgement.list[1];
			note.hitJudgement = judge;
			if(note.sustain != null)
				note.sustain.hitJudgement = judge;
			//health += judge.health * strumline.healthMult;
			judgeSpr.display(judge.timing);
			//comboNumbers.display(++combo);

			noteHitList.push({
				time: note.rawTime,
				diff: judge.timing,
				color: judge.color,
				countMean: false
			});

			return;
		}

		if (note.sound.length > 0) FlxG.sound.play(Paths.audio(note.sound));

		judgeHit(strumline, note);

		if (Settings.data.notesMoveCamera) {
			noteCamDelay = 0.5;
			var offsetToUse:FlxPoint = noteCamOffset[note.lane];
			camGame.targetOffset.set(offsetToUse.x, offsetToUse.y);
		}
	}

	dynamic function sustainHit(strumline:Strumline, note:Sustain, mostRecent:Bool) {
		ScriptHandler.call('sustainHit', [strumline, note, mostRecent]);
		noteCamDelay = 0.5;

		// if we have more stuff regarding sustain hitting, only go below this if it's animation based
		if (!mostRecent) return;

		singCharacter(strumline, note);
	}

	function judgeHit(field:Strumline, note:Note) {
		var judge:Judgement = Judgement.getFromTiming(note.hitTime);
		final divHitTime = note.hitTime / FlxG.timeScale * -1;

		if (!note.breakOnHit) {
			noteHitList.push({
				time: note.rawTime,
				diff: divHitTime,
				color: judge.color
			});
		}

		judge = ScriptHandler.call("judgeHit", [field, note, judge], true) ?? judge; // So that scripts can override judgements if required i.e for mines

		note.hitJudgement = judge;
		if(note.sustain != null)
			note.sustain.hitJudgement = judge;

		if (note.breakOnHit) {
			score -= 10;
			health -= note.missHealth * field.healthMult;
			combo = 0;
			comboBreaks++;
		} else {
			notesPlayed += judge.accuracy;
			notesHit++;
			judge.hits++;
			combo++;
			health += judge.health * field.healthMult;
			score += Math.floor(500 - (Math.pow(Math.abs(note.hitTime / judge.timing), 2.5) * 300));
		}

		accuracy = updateAccuracy();
		clearType = updateClearType();
		timingIndicator.text = '${Util.truncateFloat(divHitTime, 2)} ms';
		Main.tweenManager.cancelTweensOf(timingIndicator);
		timingIndicator.alpha = 1;
		Main.tweenManager.tween(timingIndicator, {alpha: 0}, 0.35, {ease: FlxEase.cubeIn, startDelay: 0.75});

		if (Settings.data.hitErrorBar)
			hitErrorBar.registerHit(note.hitTime * -1);

		if (judge.breakCombo) {
			if (combo >= 50 && gf.animation.exists('sad')) {
				gf.playAnim('sad');
				gf.specialAnim = true;
			}

			combo = 0;
			comboBreaks++;
			if (Settings.data.gameplayModifiers["instakill"])
				death();
		}

		if (!judge.splashes && Settings.data.gameplayModifiers["onlySicks"])
			death();

		updateInfo();
		judgeSpr.display(note.hitTime);
		switch (Settings.data.comboTinting){
			case 'Clear Flag':
				var colour:FlxColor = FlxColor.WHITE;
				if(comboBreaks == 0){
					for(i in 0...Judgement.list.length){
						if(Judgement.list[i].hits > 0)
							colour = Judgement.list[i].color;
					}
				}
				comboNumbers.color = colour;
			case 'Per-Note':
				comboNumbers.color = judge.color;
		}

		if (!judge.breakCombo)
			comboNumbers.display(combo);
		else
			comboNumbers.clearNums();

		if (Settings.data.noteSplashSkin != 'none' && judge.splashes) {
			final splash = noteSplashes.members[note.lane];
			if(Settings.data.strumGlow == 'Judgement'){
				splash.luminColors = true;
				splash.color = judge.color;
			} else {
				splash.luminColors = note.luminColors;
				splash.color = note.color;
			}
			splash.hit(field.members[note.lane]);
		}

		ScriptHandler.call("postJudgeHit", [field, note, judge]); // i KNOW post functions are lame i KNOW but i NEED THIs so im not DOING SHIT EVERY FRAME FOR NO REASON FOR MY JUDGE SKIN SCRIPT -neb

		judge = null;
	}

	function loadHUD():Void {
		hud.clear();

		hud.add(hitErrorBar = new HitErrorBar(0, downscroll ? FlxG.height - 50 : 45));
		hitErrorBar.screenCenter(X);
		hitErrorBar.visible = Settings.data.hitErrorBar;

		hud.add(timingIndicator = new FlxText(0, hitErrorBar.y + 20, 500, '0 ms', 16));
		timingIndicator.alignment = 'center';
		timingIndicator.screenCenter(X);
		timingIndicator.alpha = 0;
		timingIndicator.font = Paths.font('LineSeed.ttf');
		timingIndicator.borderSize = 1.25;
		timingIndicator.borderStyle = OUTLINE;
		timingIndicator.borderColor = 0xFF000000;

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, function() return health, 0, 100));
		healthBar.setColors(dad.healthColor, bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.alpha = Settings.data.healthBarAlpha;
		healthBar.leftToRight = false;

		hud.add(iconP1 = new CharIcon(bf.icon, true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP1.scale.set(0.8, 0.8);
		iconP1.updateHitbox();
		iconP1.alpha = Settings.data.healthBarAlpha;

		hud.add(iconP2 = new CharIcon(dad.icon));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		iconP2.scale.set(0.8, 0.8);
		iconP2.updateHitbox();
		iconP2.alpha = Settings.data.healthBarAlpha;

		updateIconPositions();

		// fuck it im pulling a forever engine
		hud.add(timeText = new FlxText(0, 15, 500, '$songName (Starting...)', 18));
		timeText.screenCenter(X);
		timeText.alignment = 'center';
		timeText.font = Paths.font('LineSeed.ttf');
		timeText.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeText.borderSize = 1.5;

		hud.add(infoText = new FlxText(0, 680, FlxG.width, '', 18));
		infoText.alignment = 'center';
		infoText.font = Paths.font('LineSeed.ttf');
		infoText.borderStyle = FlxTextBorderStyle.OUTLINE;
		infoText.borderSize = 1.5;

		hud.add(judgeNames = new FlxText(5, 0, 140, '', 18));
		judgeNames.font = Paths.font('LineSeedB.ttf');
		judgeNames.visible = Settings.data.judgementCounter;
		judgeNames.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeNames.borderSize = 1.5;
		judgeNames.color = 0xFF999999; // sets the default format color to the miss color
		//@:privateAccess judgeNames._defaultFormat.leading = 5;

		hud.add(judgeCounter = new FlxText(judgeNames.x, judgeNames.y, judgeNames.fieldWidth, '', judgeNames.size));
		judgeCounter.font = Paths.font('LineSeed.ttf');
		judgeCounter.alignment = RIGHT;
		judgeCounter.visible = Settings.data.judgementCounter;
		judgeCounter.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeCounter.borderSize = 1.5;
		//judgeCounter.color = 0xFF999999; // sets the default format color to the miss color
		//@:privateAccess judgeCounter._defaultFormat.leading = 5;
		regenJudgeCounter();
		judgeNames.screenCenter(Y);
		judgeCounter.y = judgeNames.y;

		hud.add(ranking = new FlxText(judgeNames.x, 0, judgeCounter.fieldWidth, '?'));
		ranking.setFormat(Paths.font('cafeSquare.ttf'), 20, 0xFF000000, CENTER, OUTLINE, 0xFF000000);
		ranking.x = (Settings.data.gameplayModifiers['playingSide'] == 'Opponent' ? FlxG.width - 5 - ranking.width : 5);
		ranking.y = ((judgeNames.visible) ? judgeNames.y + judgeNames.height : FlxG.height - 5 - ranking.height);
		ranking.borderSize = 1.5;

		add(botplayTxt = new FunkinSprite().loadGraphic(Paths.image('ui/botplay')));
		botplayTxt.visible = false;
		botplayTxt.screenCenter();
		botplayTxt.camera = camHUD;

		updateInfo();
	}

	/**
		Regenerate the judgement counter to match the judgement list.

		Utilize this function when Judgement.list has been modified!
	**/
	public function regenJudgeCounter() {
		if (!Settings.data.judgementCounter) return;

		judgeFormats.resize(Judgement.list.length);
		judgeNames.text = "";
		judgeCounter.text = "";
		var lastNameEnd = 0;
		//var lastCountEnd = 0;
		var judgeBreaks = 0;
		for (i in 0...Judgement.list.length) {
			final judge = Judgement.list[i];

			judgeNames.text += judge.shortName + "\n";
			judgeCounter.text += judge.hits + "\n";
			if (judgeFormats[i] == null) {
				judgeFormats[i] = new FlxTextFormat(judge.color);
				//@:privateAccess judgeFormats[i].format.leading = 6;
			} else {
				@:privateAccess judgeFormats[i].format.color = judge.color;
				judgeNames.removeFormat(judgeFormats[i]);
				//judgeCounter.removeFormat(judgeFormats[i]);
			}

			judgeNames.addFormat(judgeFormats[i], lastNameEnd, judgeNames.text.length);
			//judgeCounter.addFormat(judgeFormats[i], lastCountEnd, judgeCounter.text.length);
			lastNameEnd = judgeNames.text.length;
			//lastCountEnd = judgeCounter.text.length;

			if (judge.breakCombo)
				judgeBreaks += judge.hits;
		}
		judgeNames.text += "MS";
		judgeCounter.text += comboBreaks - judgeBreaks;

		judgeNames.updateHitbox();
		judgeCounter.updateHitbox();
	}

	dynamic function ghostTap(strumline:Strumline, dir:Int, shouldMiss:Bool)
	{
		if (shouldMiss)
		{
			if (ScriptHandler.call('ghostTapMiss', [strumline, dir]) == -1) return;

			onMiss(strumline, Note.defaultMissHealth, true, dir, '');
		}
	}

	dynamic function noteMiss(strumline:Strumline, note:Note) {
		if (ScriptHandler.call('noteMiss', [strumline, note]) == -1) return;
		if (note.ignore || note.player != playerID) return;

		onMiss(strumline, note.missHealth, !note.noAnimation, note.lane, note.animSuffix);

		noteHitList.push({
			time: note.rawTime,
			diff: Judgement.max.timing,
			color: 0xFFFFFFFF,
			countMean: false
		});
	}

	function onMiss(strumline:Strumline, missHealth:Float, animation:Bool, dir:Int, animSuffix:String) {
		if (combo >= 50 && gf.animation.exists('sad')) {
			gf.playAnim('sad');
			gf.specialAnim = true;
		}

		score -= 10;
		comboBreaks++;
		combo = 0;

		health -= missHealth * strumline.healthMult;

		if (Settings.data.hitErrorBar)
			hitErrorBar.registerMiss();

		if (Settings.data.gameplayModifiers["instakill"] || Settings.data.gameplayModifiers["onlySicks"])
			death();

		accuracy = updateAccuracy();
		clearType = updateClearType();
		updateInfo();

		var curCharacter:Character = strumline.character();

		if (curCharacter != null && animation)
			curCharacter.playAnim('miss${Note.directions[dir].toUpperCase()}', true, animSuffix);
	}

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.RED);
	function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;

		judgeCounter.text = "";
		var lastCountEnd = 0;
		var judgeBreaks = 0;
		for (i in 0...Judgement.list.length) {
			final judge = Judgement.list[i];

			judgeCounter.text += judge.hits + "\n";
			/*
			// don't do what i'm doing. i just wanted to reduce cycles since i can trust my ranges to be sorted and regenerated.
			@:privateAccess final range = judgeCounter._formatRanges[i].range;
			range.start = lastCountEnd;
			range.end = judgeCounter.text.length;
			lastCountEnd = judgeCounter.text.length;
			*/

			if (judge.breakCombo)
				judgeBreaks += judge.hits;
		}
		judgeCounter.text += comboBreaks - judgeBreaks;
	}

	function updateClearType():String {
		var sicks:Int = Judgement.list[0].hits;
		var goods:Int = Judgement.list[1].hits;
		var bads:Int = Judgement.list[2].hits;
		var shits:Int = Judgement.list[3].hits;

		var type:String = 'N/A';

		if (comboBreaks == 0) {
			if (bads > 0) type = 'FC';
			else if (goods > 0) {
				if (goods == 1) type = 'BF';
				else if (goods <= 9) type = 'SDG';
				else if (goods >= 10) type = 'GFC';
			} else if (sicks > 0) type = 'MFC';
		} else {
			if (comboBreaks == 1) type = 'MF';
			else if (comboBreaks <= 9) type = 'SDCB';
			else type = 'Clear';
		}

		return type;
	}

	inline function updateAccuracy():Float {
		return notesPlayed / (notesHit + comboBreaks);
	}

	function updateInfo():Void {
		updateJudgeCounter();
		final rank:Ranking = (notesHit == 0) ? {} : Ranking.getFromAccuracy(accuracy);

		ranking.text = '${rank.name} | $clearType';
		ranking.color = rank.color;

		infoText.text = 'Score: ${Util.moneyString(score)} | Combo Breaks: $comboBreaks';
		if(!Settings.data.hideAcc)
			infoText.text += ' | Accuracy: ${Util.truncateFloat(accuracy)}%';

		ScriptHandler.call("updateInfo", []);
	}

	function loadSong():Void {
		song = Song.load(songID, Difficulty.current);

		if (Conductor.inst != null){
			Conductor.inst.stop();
			Conductor.inst = null;
		}

		if (Song.exists(songID, 'gf')) {

			var middleNotes:Chart = Song.load(songID, 'gf');
			for (note in middleNotes.notes) {
				note.player = 2;
				song.notes.push(note);
			}
		}

		Conductor.offset = song.meta.offset;
		Conductor.timingPoints = song.meta.timingPoints;
		Conductor.bpm = Conductor.timingPoints[0].bpm;

		stageName = song.meta.stage;
		songName = song.meta.songName;

		// load inst
		try {
			if (Conductor.inst != null) Conductor.inst.stop();
			Conductor.inst = FlxAudioHandler.loadAudio(Paths.audioPath('songs/$songID/Inst'));
			Conductor.inst.pitch = FlxG.timeScale;
			Conductor.inst.onComplete = function() songCompleted();

		} catch (e:Dynamic) {
			Sys.println('Instrumental failed to load: $e');
		}

		// load vocals
		try {
			if (song.meta.hasVocals) {
				var folder:String = 'songs/$songID';
				var mainFilePath:String = '$folder/Vocals-Player';
				var opponentFilePath:String = '$folder/Vocals-Opponent';

				var mainFile:FlxAudio = Paths.exists('$mainFilePath.ogg') ?
				FlxAudioHandler.loadAudio(Paths.audioPath(mainFilePath)) :
				FlxAudioHandler.loadAudio(Paths.audioPath('$folder/Vocals'));

				var opponentFile:FlxAudio = Paths.exists('$opponentFilePath.ogg') ?
				FlxAudioHandler.loadAudio(Paths.audioPath(opponentFilePath)) :
				null;

				Conductor.mainVocals = mainFile;
				if (opponentFile != null) Conductor.opponentVocals = opponentFile;
			}
		} catch (e:Dynamic) {
			Sys.println('Vocals failed to load: $e');
		}

		ScriptHandler.loadFromDir('songs/$songID');
		ScriptHandler.call('loadSong', [song]);

		playfield.load(song.notes);
		playfield.scrollSpeed /= FlxG.timeScale;

		for (noteData in playfield.unspawnedNotes) {
			if (noteData.player != playerID || playfield.mineTypes.contains(noteData.type)) continue;
			totalNotes++;
		}

		trace('total amount of hittable notes: $totalNotes');
	}

	@:unreflective
	function songCompleted() {
		if (disqualified) {endSong(); return;}
	
		Scores.setPlay({
			songID: songID,
			difficulty: Difficulty.current,

			score: score,
			accuracy: accuracy,

			modifiers: Settings.data.gameplayModifiers.copy()
		});

		if (storyMode) {
			storyScore += score;
			if (currentLevel == songList.length - 1) {
				Scores.setWeekPlay({
					weekID: weekData.fileName,
					difficulty: Difficulty.current,
					score: storyScore,
					modifiers: Settings.data.gameplayModifiers.copy()
				});
				weekData = null;
				storyScore = 0;
			}
		}

		endSong();
		Scores.save();
	}

	// forceLeave:Bool - forces you to leave to the main menu
	public function endSong(?forceLeave:Bool = false) {
		if (!forceLeave && ScriptHandler.call('onEndSong', [songID], true) == -1) return;
		//trace('bro'); //bro, remember to disable ur traces :bartcoal:

		FlxG.timeScale = 1;
		Conductor.stop();
		if (Conductor.vocals != null) {
			Conductor.vocals.destroy();
			Conductor.vocals = null;
		}
		deaths = 0;

		Util.cancelAllTimers();
		Util.cancelAllTweens();

		// should automatically leave if you're not in story mode
		var exitToMenu:Bool = !storyMode;
		if (storyMode) 
			++currentLevel < songList.length ? FunkinState.resetState() : exitToMenu = true;

		if (exitToMenu || forceLeave) {
			persistentUpdate = false;
			Conductor.inst = FlxAudioHandler.loadMusic(Paths.audioPath('freakyMenu'), true);
			Conductor.play();
			Difficulty.reset();
			Addons.current = '';
			Paths.clearUnusedMemory();
			FunkinState.switchState(new FreeplayState());
			songList.resize(0);
			storyMode = false;
			currentLevel = 0;
			disqualified = false;
		}
	}

	override function destroy():Void {
		ScriptHandler.call('destroy');
		Judgement.reset();
		ScriptHandler.clear();
		FlxG.mouse.visible = true;
		self = null;
		Conductor.vocals = null;
		noteHitList.resize(0);
		super.destroy();
	}

	function updateCameraScale(delta:Float):Void {
		if (isZooming) return;

		final scalingMult:Float = Math.exp(-delta * 6);
		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, scalingMult);
		camHUD.zoom = FlxMath.lerp(defaultHudZoom, camHUD.zoom, scalingMult);
	}

	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconStates() {
		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	}

	dynamic function updateIconScales(delta:Float):Void {
		var mult:Float = FlxMath.lerp(0.8, iconP1.scale.x, Math.exp(-delta * 9));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(0.8, iconP2.scale.x, Math.exp(-delta * 9));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	dynamic function updateTimeText() {
		var current:String = flixel.util.FlxStringUtil.formatTime(Conductor.rawTime * 0.001, false);
		var duration:String = flixel.util.FlxStringUtil.formatTime(Conductor.inst.length * 0.001, false);

		timeText.text = '$songName ($current / $duration)';
	}

	override function stepHit(step:Int) {
		ScriptHandler.call('stepHit', [step]);
	}

	override function beatHit(beat:Int) {
		iconP1.scale.set(1, 1);
		iconP1.updateHitbox();

		iconP2.scale.set(1, 1);
		iconP2.updateHitbox();

		characterBopper(beat);

		ScriptHandler.call('beatHit', [beat]);

		if (metronome && Conductor.rawTime >= 0) {
			FlxG.sound.play(Paths.audio('metronome', 'sfx'));
		}
	}

	// i added this check to prevent that ugly ahh jittering
	override function measureHit(measure:Int) {
		if (Settings.data.cameraZooms.toLowerCase() != 'off' && !isZooming) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.0075;
		}

		ScriptHandler.call('measureHit', [measure]);
	}

	function characterBopper(beat:Int):Void {
		for (char in [gf, bf, dad]) {
			final interval = char == gf ? (gfSpeed * char.danceInterval) : char.danceInterval;
			if (char.specialAnim || beat % interval != 0 || !char.active)
				continue;
			char.dance();
		}
	}

	// have to make it a function instead because dce lol
	function loadVideo(path:String):FunkinVideo {
		return new FunkinVideo(Paths.video(path), true);
	}

	var alreadyDying:Bool = false;
	function death():Void {
		if (alreadyDying) return;

		if (Settings.data.gameplayModifiers["noFail"]) {
			if (!disqualified) disqualified = true;
			return;
		}

		disqualified = true;
		alreadyDying = true;
		deaths++;

		Util.cancelAllTimers();
		Util.cancelAllTweens();

		for (strumline in playfield.strumlines) {
			for (strum in strumline.members) {
				Main.tweenManager.tween(strum, {
					x: strum.x + FlxG.random.int(-50, 50),
					y: strum.y + FlxG.random.int(-100, 100),
					angle: FlxG.random.int(-40, 40)
				}, FlxG.random.int(2, 4), {ease: FlxEase.quadInOut});
			}
		}

		camHUD.fade(0x42FF0000, 5);
		FlxTween.tween(camGame, {zoom: camGame.zoom + 0.5, angle: (FlxG.random.bool() ? -10 : 10)}, 5, {ease: FlxEase.linear});

		if (Conductor.vocals != null)
			FlxTween.tween(Conductor.vocals, {pitch: 0.1}, 5, {ease: FlxEase.linear});

		FlxTween.tween(Conductor.inst, {pitch: 0.1}, 5, {ease: FlxEase.linear, 
			onComplete: t -> {
				Conductor.stop();
				Util.cancelAllTimers();
				Util.cancelAllTweens();
				final substate:funkin.states.BlueBalledState = new funkin.states.BlueBalledState(camOther, playfield.playerID);
				openSubState(substate);
			}});
	}
}
