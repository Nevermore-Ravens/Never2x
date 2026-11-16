package funkin.signals;

import funkin.objects.NoteSplash;
import funkin.objects.Character;
import nevermore.play.Strumline;
import lime.app.Event;
import nevermore.play.Sustain;
import nevermore.play.Note;

class SustainTick {
	var signal:Event<SustainTick->Void> = new Event<SustainTick->Void>();

	/**
		The scene associated with the tick.
	**/
	public var game:PlayState;
	/**
		The sustain associated with the tick.
	**/
	public var sustain:Sustain;
	/**
		The note associated with the tick.
	**/
	public var strumline:Strumline;

	/**
		Whether or not the inputted sustain was the most recent sustain hit.
	**/
	public var mostRecent:Bool;
	/**
		If the tick was caused from the player's main strumline.
	**/
	public var player:Bool;

	/**
		The character that will play an animation, or `null` to cancel animation playing.

		Will be `null` if 
	**/
	public var character:Character;
	/**
		The animation `character` will play.

		By default "sing[NOTE-DIRECTION]".
	**/
	public var animation:String;
	/**
		Additional text to append to the playing animation, if `animation + animationSuffix` doesn't exist, `animation` will play instead.
	**/
	public var animationSuffix:Null<String>;

	/**
		How much health to gain from the hold tick.

		By default `0`.
	**/
	public var health:Float;
	/**
		If the hold tick should apply to the players score.

		By default the value of `player`.
	**/
	public var applyToScore:Bool;
	/**
		If the hold tick should apply to the players accuracy.

		By default the value of `player`.
	**/
	public var applyToAccuracy:Bool;


	public function add(func:SustainTick->Void) {
		signal.add(func);
	}
	public function emit() {
		signal.dispatch(this);
	}

	public function reset(game:PlayState, strumline:Strumline, sustain:Sustain, mostRecent:Bool) {
		this.game = game;
		this.sustain = sustain;
		this.strumline = strumline;

		this.mostRecent = mostRecent;
		player = !game.notefield.autoplay && game.notefield.playerID == sustain.player;

		character = mostRecent ? game.getCharacter(sustain.player) : null;
		animation = "sing" + Note.directions[sustain.lane % Note.directions.length].toUpperCase();
		animationSuffix = null;
		
		health = 0;
		applyToScore = player;
		applyToAccuracy = player;
	}

	public function new() {}
}