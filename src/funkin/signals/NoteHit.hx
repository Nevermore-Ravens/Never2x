package funkin.signals;

import funkin.objects.NoteSplash;
import funkin.objects.Character;
import nevermore.play.Strumline;
import lime.app.Event;
import nevermore.play.Note;

class NoteHit {
	var signal:Event<NoteHit->Void> = new Event<NoteHit->Void>();
	var signalPost:Event<NoteHit->Void> = new Event<NoteHit->Void>();

	/**
		The scene associated with the hit.
	**/
	public var game:PlayState;
	/**
		The note associated with the hit.
	**/
	public var note:Note;
	/**
		The note associated with the hit.
	**/
	public var strumline:Strumline;

	/**
		If the note hit was caused from the player's main strumline.
	**/
	public var player:Bool;

	/**
		The character that will play an animation, or `null` to cancel animation playing.
	**/
	public var character:Character;
	/**
		The animation `character` will play.

		By default "sing[NOTE-DIRECTION]"/"miss[NOTE-DIRECTION]" depending on if the hit doesn't/does break combo.
	**/
	public var animation:String;
	/**
		Additional text to append to the playing animation, if `animation + animationSuffix` doesn't exist, `animation` will play instead.
	**/
	public var animationSuffix:Null<String>;
	/**
		Whether or not the game will try to prevent dancing before the animation finishes.
	**/
	public var specialAnim:Bool;

	/**
		How much health to gain from the note hit.

		By default judgement or type behavior dependant.
	**/
	public var health:Float;
	/**
		If the note hit should apply to the players score.

		By default the value of `player`.
	**/
	public var applyToScore:Bool;
	/**
		If the note hit should apply to the players accuracy.

		By default the value of `player`.
	**/
	public var applyToAccuracy:Bool;
	/**
		If the game should register the note hit for the graph and hit error bar.

		By default the value of `player`.
	**/
	public var registerHit:Bool;

	/**
		What note splash skin the game should use, or `null` to cancel splash spawning.

		By default the value of `game.splashSkin` if the receptor should glow, is a `player` hit, and `game.splashSkin` wasn't "none", otherwise `null`.
	**/
	public var noteSplash:Null<String>;
	/**
		What color the note splash (if spawned) will take.
	**/
	public var splashColor:FlxColor;
	/**
		If the note splash (if spawned) should apply the custom color method.
	**/
	public var luminzeSplash:Bool;
	/**
		The note splash spawned with the note hit.

		Only availible if called on post and `noteSplash` wasn't null.
	**/
	public var spawnedSplash:NoteSplash;

	/**
		If the judgement popup should show.

		By default the value of `player`.
	**/
	public var displayJudge:Bool;
	/**
		If the combo popup should show.

		By default the value of `player`.
	**/
	public var displayCombo:Bool;

	/**
		How off in miliseconds the note hit was.

		Set to `0` if `player` is `false`.
	**/
	public var deviation:Float;
	/**
		The index where `note.judgement` could be found.
	**/
	public var judgementIndex:Int;

	public function add(func:NoteHit->Void) {
		signal.add(func);
	}
	public function addPost(func:NoteHit->Void) {
		signalPost.add(func);
	}

	public function emit() {
		signal.dispatch(this);
	}
	public function emitPost() {
		signalPost.dispatch(this);
	}

	public function reset(game:PlayState, strumline:Strumline, note:Note) {
		this.game = game;
		this.note = note;
		this.strumline = strumline;

		player = !game.notefield.autoplay && game.notefield.playerID == note.player;
		deviation = player ? note.getDeviation(game.notefield.input.timestamp) : 0;
		judgementIndex = Judgement.current.indexOf(note.judgement);
		
		character = game.getCharacter(note.player);
		animation = (player && note.judgement.breaksCombo ? "miss" : "sing") + Note.directions[note.lane % Note.directions.length].toUpperCase();
		animationSuffix = null;
		specialAnim = false;
		
		health = player ? ((note.behavior.hitHealth ?? note.judgement.health) * note.behavior.healthMult) : 0;
		applyToScore = player;
		applyToAccuracy = player;
		registerHit = player;

		noteSplash = (!player || !note.canGlow || game.splashSkin == "none" || judgementIndex > 1) ? null : game.splashSkin;
		luminzeSplash = note.canGlow && note.glowColor != null;
		splashColor = luminzeSplash ? cast note.glowColor : 0xFFFFFFFF;
		spawnedSplash = null;

		displayJudge = player && !note.behavior.punishable;
		displayCombo = player;
	}

	public function new() {}
}