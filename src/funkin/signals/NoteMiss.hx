package funkin.signals;

import funkin.objects.Character;
import nevermore.play.Strumline;
import lime.app.Event;
import nevermore.play.Note;

class NoteMiss {
	var signal:Event<NoteMiss->Void> = new Event<NoteMiss->Void>();

	/**
		The scene associated with the miss.
	**/
	public var game:PlayState;
	/**
		The note associated with the miss.
	**/
	public var note:Note;
	/**
		The note associated with the miss.
	**/
	public var strumline:Strumline;

	/**
		The character that will play an animation, or `null` to cancel animation playing.
	**/
	public var character:Character;
	/**
		The animation `character` will play.

		By default "miss[NOTE-DIRECTION]".
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
		How much health to get from the miss.

		By default type behavior dependant, most likely `-10.5`.
	**/
	public var health:Float;
	/**
		If the miss should apply to the players score.

		On by default.
	**/
	public var applyToScore:Bool;
	/**
		If the miss should apply to the players accuracy.

		On by default.
	**/
	public var applyToAccuracy:Bool;
	/**
		If the game should break combo and register on the graph and hit error bar.

		On by default.
	**/
	public var registerMiss:Bool;

	/**
		If the judgement popup should show.

		On by default.
	**/
	public var displayJudge:Bool;
	/**
		If the combo popup should show.

		On by default.
	**/
	public var displayCombo:Bool;

	public function add(func:NoteMiss->Void) {
		signal.add(func);
	}
	public function emit() {
		signal.dispatch(this);
	}

	public function reset(game:PlayState, strumline:Strumline, note:Note) {
		this.game = game;
		this.note = note;
		this.strumline = strumline;

		character = game.getCharacter(note.player);
		animation = "miss" + Note.directions[note.lane % Note.directions.length].toUpperCase();
		animationSuffix = null;
		specialAnim = false;
		
		health = (note.behavior.hitHealth ?? -10.5) * note.behavior.healthMult;
		applyToScore = true;
		applyToAccuracy = true;
		registerMiss = true;

		displayJudge = true;
		displayCombo = true;
	}

	public function new() {}
}