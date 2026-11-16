package funkin.signals;

import funkin.objects.Character;
import nevermore.play.Strumline;
import lime.app.Event;
import nevermore.play.Sustain;
import nevermore.play.Note;

class SustainDrop {
	var signal:Event<SustainDrop->Void> = new Event<SustainDrop->Void>();

	/**
		The scene associated with the clear.
	**/
	public var game:PlayState;
	/**
		The sustain associated with the clear.
	**/
	public var sustain:Sustain;
	/**
		The note associated with the clear.
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
		How much health to get from the drop.

		By default `0`.
	**/
	public var health:Float;
	/**
		If the drop should apply to the players score.

		On by default.
	**/
	public var applyToScore:Bool;
	/**
		If the drop should apply to the players accuracy.

		On by default.
	**/
	public var applyToAccuracy:Bool;
	/**
		If the game should break combo and register on the graph and hit error bar.

		On by default.
	**/
	public var registerDrop:Bool;

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

	public function add(func:SustainDrop->Void) {
		signal.add(func);
	}
	public function emit() {
		signal.dispatch(this);
	}

	public function reset(game:PlayState, strumline:Strumline, sustain:Sustain) {
		this.game = game;
		this.sustain = sustain;
		this.strumline = strumline;

		character = game.getCharacter(sustain.player);
		animation = "miss" + Note.directions[sustain.lane % Note.directions.length].toUpperCase();
		animationSuffix = null;
		
		health = 0;
		applyToScore = true;
		applyToAccuracy = true;
		registerDrop = true;

		displayJudge = true;
		displayCombo = true;
	}

	public function new() {}
}