package funkin.states;

import nevermore.play.NoteField;
import nevermore.play.Strumline;
import nevermore.play.Note;
import nevermore.play.Statistics;

class CalibrateOffsetState extends FunkinState {
	var notefield:NoteField;
	var strumline:Strumline;

	var extraTime:Float = 1500; // 1.5 seconds

	var introText:FlxText;
	var introBG:FlxSprite;
	var finished:Bool = false;
	var skipIntro:Bool = false;

	var stats:Statistics = {};

	var finalOffset:Float = 0;

	public function new(?skipIntro:Bool = false):Void {
		super();
		this.skipIntro = skipIntro;
	}

	override function create():Void {
		super.create();
		Conductor.stop();

		var downscroll:Bool = Settings.data.scrollDirection == 'Down';
		var skin = NoteStyling.getSkinAndStyle(Settings.data.noteSkin, 'normal');
		var strumlineHeight:Float = skin.spacing * Settings.data.strumSize;
		var strumlineYPos:Float = downscroll ? FlxG.height - 50 - strumlineHeight : 50;
		
		strumline = new Strumline(0, strumlineYPos, skin);
		strumline.screenCenter(X);

		add(notefield = new NoteField([strumline]));
		notefield.scrollDirection = Settings.data.scrollDirection;
		notefield.assistTicks = true;
		notefield.noteHit = noteHit;
		notefield.visible = skipIntro;
		notefield.active = skipIntro;

		load();
		
		// don't need to worry about offset for this one
		Conductor.audioTime = -extraTime;
		if (skipIntro) start();

		add(introBG = new FlxSprite().makeGraphic(1, 1, FlxColour.BLACK));
		introBG.scale.set(FlxG.width, FlxG.height);
		introBG.updateHitbox();
		introBG.visible = !skipIntro;
		introBG.alpha = skipIntro ? 0 : 1;

		add(introText = new FlxText(0, 0, FlxG.width, "
			Welcome to the offset calibration menu!\nThis is where you set your input offset, so your taps are in sync with the song.\nDon't sweat it, and don't focus on the visuals too much.\n\nGood luck!
		", 25));
		introText.font = Assets.getPath('fonts/LineSeed.ttf');
		introText.alignment = 'center';
		introText.screenCenter();
		introText.visible = !skipIntro;
		introText.alpha = skipIntro ? 0 : 1;
	}

	var songID:String = 'Sync Test';
	function load():Void {
		var song:Chart = Song.load('music', 'Test');

		Conductor.inst = Util.makeSound(Assets.audio('music/Test.ogg'));
		Conductor.inst.onComplete = finish;

		notefield.load(song);
		notefield.scrollSpeed = Settings.data.scrollSpeed;
	}

	function finish():Void {
		finalOffset = Math.floor(stats.mean);
		var direction:String = finalOffset > 0 ? 'later' : 'earlier';
		var msSuffix:String = Math.abs(finalOffset) != 1 ? 's' : '';

		introText.text = 'Your approximated offset is: $finalOffset millisecond$msSuffix ($direction).\n\nPress Accept to confirm.\nPress Back to retry.';
		introText.screenCenter();

		finished = true;
		Conductor.clock.active = false;

		FlxTween.tween(introBG, {alpha: 1}, 0.5, {onComplete: function(_) notefield.visible = false});
		FlxTween.tween(introText, {alpha: 1}, 0.5);
		introBG.visible = true;
		introText.visible = true;
	}

	function start():Void {
		Conductor.clock.active = true;
		new FlxTimer().start(extraTime / 1000, function(_) Conductor.play());
		notefield.active = true;

		if (skipIntro) return;

		notefield.visible = true;
		
		FlxTween.tween(introBG, {alpha: 0}, 0.5);
		FlxTween.tween(introText, {alpha: 0}, 0.5);
	}

	override function update(delta:Float):Void {
		super.update(delta);

		if (finished && Controls.justPressed('accept')) {
			Settings.data.inputOffset = finalOffset;
			Settings.updateNevermore();
			FlxG.switchState(new OptionsState());
		}

		if (Controls.justPressed('back')) {
			if (finished) FlxG.switchState(new CalibrateOffsetState(true));
			else {
				FunkinState.skipNextTransIn = true;
				FunkinState.switchState(new OptionsState());
			}
		} else if (!Conductor.clock.active && !finished && Controls.justPressed('accept')) start();
	}

	function noteHit(_, note:Note):Void {
		stats.registerHit({
			deviation: note.getDeviation(notefield.input.timestamp)
		});
	}
}