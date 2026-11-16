package funkin.signals;

import nevermore.play.Strumline;
import lime.app.Event;
import nevermore.play.Sustain;

class SustainFinish {
	var signal:Event<SustainFinish->Void> = new Event<SustainFinish->Void>();

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
		If the clear was reliant on release timing.
	**/
	public var releaseTimed:Bool;
	/**
		If the clear was caused from the player's main strumline.
	**/
	public var player:Bool;

	/**
		How much health to gain from the clear.

		By default `0`.
	**/
	public var health:Float;

	/**
		The judgement grabbed from the clear's `deviation`, or the highest possible if there was no release timing.
	**/
	public var judgement:Judgement;
	/**
		If the game should apply a hit to the judgement and popup.

		By default reliant on if there was release timing and if `player` is on.
	**/
	public var registerJudge:Bool;

	/**
		How off in miliseconds the sustain clear was.

		Set to `0` if it was a roll or there was no release timing.
	**/
	public var deviation:Float;

	public function add(func:SustainFinish->Void) {
		signal.add(func);
	}
	public function emit() {
		signal.dispatch(this);
	}

	public function reset(game:PlayState, strumline:Strumline, sustain:Sustain, deviation:Float) {
		this.game = game;
		this.sustain = sustain;
		this.strumline = strumline;

		player = !game.notefield.autoplay && game.notefield.playerID == sustain.player;
		releaseTimed = !game.notefield.releaseTimings || sustain.isRoll;

		this.deviation = releaseTimed ? deviation : 0;
		judgement = Judgement.get(this.deviation);
		registerJudge = releaseTimed && player;
	}

	public function new() {}
}