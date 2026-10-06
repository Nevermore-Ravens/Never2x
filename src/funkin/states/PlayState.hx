package funkin.states;

import nevermore.core.Chart;
import nevermore.play.*;
import nevermore.play.note.*;
import nevermore.skins.Noteskin;

class PlayState extends FunkinState {
	public static var songID:String = '';
	var chart:Chart;

	var notefield:NoteField;
	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	var noteSkin:String = 'funkin';
	var extraTime:Float = 2500; // 2.5 seconds

	override function create():Void {
		super.create();
		Conductor.stop();

		Conductor.metronome = Settings.data.metronome;

		noteSkin = Settings.data.noteSkin;

		var skin:Noteskin = Noteskin.get('images/noteSkins/' + noteSkin);
		var strumlineYPos:Float = /*downscroll ? FlxG.height - 50 - skin.spacing * Settings.data.strumSize :*/ 50;

		leftStrumline = new Strumline(320, strumlineYPos, skin);
		rightStrumline = new Strumline(960, strumlineYPos, skin);

		add(notefield = new NoteField([leftStrumline, rightStrumline], 1));
		notefield.assistTicks = Settings.data.assistTicks;
		notefield.scrollSpeed = Settings.data.scrollSpeed;

		load();
	}

	function load() {
		chart = Song.load('songs/$songID', Difficulty.current);

		notefield.load(chart);
		Conductor.clock.reset(chart.timingPoints);
		Conductor.clock.offset = chart.offset;

		Conductor.inst = FlxG.sound.load(Assets.audio('songs/$songID/Inst'));

		if (Assets.exists('songs/$songID/Vocals.ogg')) {
			Conductor.vocals = FlxG.sound.load(Assets.audio('songs/$songID/Vocals'));
		}

		Conductor.audioTime = -extraTime;
		Conductor.clock.active = true;
		new FlxTimer().start(extraTime / 1000, function(_) {
			Conductor.play();
		});
	}
}