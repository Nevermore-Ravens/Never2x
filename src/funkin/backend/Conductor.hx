package funkin.backend;

import flixel.util.FlxSignal;
import funkin.backend.Meta;
import funkin.backend.Song;
import funkin.backend.audio.FlxAudioGroup;

@:structInit
class TimingPoint {
	public var offsettedTime(get, never):Float;
	function get_offsettedTime():Float return time + Conductor.offset;

	public var time:Float = 0;
	public var bpm:Float = 120;
	public var beatsPerMeasure:ByteUInt = 4;

	public function toString():String {
		return 'Time: $time | Tempo: $bpm | Beats per measure: $beatsPerMeasure';
	}
}

class Conductor extends flixel.FlxBasic {
	public static var quants:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];
	
	public static var playing:Bool = false;
	public static var length:Float = 0.0;

	public static var bpm(default, set):Float = 120.0;
	public static var crotchet:Float = (60 / bpm) * 1000;
	public static var stepCrotchet:Float = crotchet * 0.25;

	public static var beatsPerMeasure(default, set):ByteUInt = 4;
	
	public static var offset:Float = 0.0;

	static var _songPlaying:Bool = false;

	public static var volume(default, set):Float = 1.0;

	public static var time:Float = 0.0;
    public static var rawTime:Float = 0.0;

	//static var _lastTime:Float = 0.0;
	static var _resyncTimer:Float = 0.0;

    public static var timingPoints(default, set):Array<TimingPoint> = [];
    static function set_timingPoints(value:Array<TimingPoint>):Array<TimingPoint> {
		if (value == null || value.length == 0) {
			timingPoints.resize(1);
			timingPoints[0] = {};
			return timingPoints;
		}

/*        var lastPoint:TimingPoint = {
			bpm: 0,
			beatsPerMeasure: 0
		};

        // so that the end-user doesn't have to specify a bpm/numerator every time they add a new point for smth else
		// nvm this shit is NOT worth the hassle
        for (point in value) {
            if (point.bpm <= 0) point.bpm = lastPoint.bpm;
            if (point.beatsPerMeasure <= 0) point.beatsPerMeasure = lastPoint.beatsPerMeasure;
            lastPoint = point;
        }*/
        timingPoints.resize(0);
        timingPoints = value.copy();

        timingPoints.sort((a, b) -> return Std.int(a.time - b.time));

        return value;
    }


	public static var inst:FlxAudio;
	public static var vocals:FlxAudioGroup;
    @:isVar public static var mainVocals(get, set):FlxAudio;
    @:isVar public static var opponentVocals(get, set):FlxAudio;

	public static final vocalResyncDiff:Float = 16.0;

	public static var step:Int = 0;
	public static var beat:Int = 0;
	public static var measure:Int = 0;
	public static var floatStep:Float;
	public static var floatBeat:Float;
	public static var visualBeat:Float;
	public static var floatMeasure:Float;

	static var _prevStep:Int = -1;
	static var _prevBeat:Int = -1;
	static var _prevMeasure:Int = -1;

	public static var onStep:FlxTypedSignal<Int -> Void>;
	public static var onBeat:FlxTypedSignal<Int -> Void>;
	public static var onMeasure:FlxTypedSignal<Int -> Void>;

	public function new() {
		super();
		visible = false;
		vocals = new FlxAudioGroup(2);
		onStep = new FlxTypedSignal<Int -> Void>();
		onBeat = new FlxTypedSignal<Int -> Void>();
		onMeasure = new FlxTypedSignal<Int -> Void>();
		reset();
	}

	public static function reset() {
        playing = false;
		@:bypassAccessor
		rawTime = 0.0;
		time = 0.0;
        _time = 0.0;

        floatStep = step = 0;
        floatBeat = beat = 0;
        floatMeasure = measure = 0;

		timingPoints = null;
		vocals.destroy();
		beatsPerMeasure = 4;
		bpm = 120;

		_songPlaying = false;

        offset = 0.0;

		onStep.removeAll();
		onBeat.removeAll();
		onMeasure.removeAll();
	}

	override function update(elapsed:Float) {
		if (!playing) return;

		_prevStep = step;
		_prevBeat = beat;
		_prevMeasure = measure;

		syncTime(elapsed);
		syncBeats();

		//if (inst != null && vocals != null && Math.abs(vocals.getActualTime() - inst.getActualTime()) > vocalResyncDiff * inst.getActualPitch())
		if (inst != null) {
			for (vocal in vocals.members) {
				if (vocal != null && Math.abs(vocal.time - inst.time) > vocalResyncDiff * inst.pitch) {
					syncMusic();
					break;
				}
			}
		}
	}

	public static var _time:Float = 0.0;
	public static dynamic function syncTime(deltaTime:Float):Void {
		if (!playing) return;

		if (inst == null || !inst.playing) {
			_time += deltaTime * 1000;
			rawTime = _time + offset;
			time = rawTime;
			return;
		}

		/*
		rawTime = inst.time + offset;
		
		if (inst.time == _lastTime)
		{
			time += deltaTime;
		}
		else
		{
			if (Math.abs(rawTime - time) >= deltaTime)
				time = rawTime;
			else
				time += deltaTime;

			_lastTime = inst.time;
		}
		*/

		time = inst.time + offset;
		rawTime = inst.time + offset;

		//time = FlxMath.lerp(inst.time + offset, rawTime, Math.exp(-deltaTime * 5));	
	}

	public static dynamic function syncMusic() {
		if (!playing || inst == null) return;

		final time:Float = _songPlaying ? inst.time : rawTime - offset;
		inst.pause();
		vocals.pause();

		//if (!_songPlaying) { ill be honest i dont get this if
			inst.time = time;
			for (vocal in vocals.members) {
				if (vocal.length <= time) continue;
				vocal.time = time;
			}
		//}

		vocals.play();
		inst.play();
	}

    public static dynamic function syncBeats() {
        var point:TimingPoint = getPointFromTime(rawTime);
		var visPoint:TimingPoint = getPointFromTime(time);
		
        if (point.bpm != 0 && point.bpm != bpm)
			bpm = point.bpm;
		if (point.beatsPerMeasure != 0 && point.beatsPerMeasure != beatsPerMeasure)
			beatsPerMeasure = point.beatsPerMeasure;

		if (timingPoints.length > 1) {
			var beatDist = (rawTime - point.time) / crotchet;
			floatBeat = getBeatFromTime(rawTime) + beatDist;
			floatMeasure = getMeasureFromTime(rawTime) + (beatDist / beatsPerMeasure);

			visualBeat = getBeatFromTime(time) + ((time - visPoint.time) / crotchet);
		} else {
			floatBeat = rawTime / crotchet;
			floatMeasure = floatBeat / beatsPerMeasure;

			visualBeat = time / crotchet;
		}
        
		floatStep = floatBeat * 4;

        var nextStep:Int = Math.floor(floatStep);
        var nextBeat:Int = Math.floor(floatBeat);
        var nextMeasure:Int = Math.floor(floatMeasure);

        if (step != nextStep) onStep.dispatch(step = nextStep);
        if (beat != nextBeat) onBeat.dispatch(beat = nextBeat);
        if (measure != nextMeasure) onMeasure.dispatch(measure = nextMeasure);
    }

	public static function stop() {
		playing = false;
		_songPlaying = false;

		if (inst != null) inst.stop();
		vocals.stop();
	}

	public static function play() {
		playing = true;
		syncMusic();
		_songPlaying = true;
	}

	public static function pause() {
		playing = false;
		if (inst != null) inst.pause();
		vocals.pause();
	}

	public static function resume() {
		playing = true;
		if (_songPlaying) syncMusic();
	}

    static function set_bpm(value:Float):Float {
        crotchet = calculateCrotchet(value);
        stepCrotchet = crotchet * 0.25;

		if (timingPoints.length == 1) {
			timingPoints[0].bpm = value;
		}

        return bpm = value;
    }

	static function set_beatsPerMeasure(value:Int):Int {
		if (timingPoints.length == 1) {
			timingPoints[0].beatsPerMeasure = value;
		}

		return beatsPerMeasure = value;
	}

	static function set_volume(value:Float):Float {
		inst.volume = value;
		vocals.volume = value;

		return volume = value;
	}

    static function get_mainVocals():FlxAudio {
        return vocals.members[1];
    }

    static function get_opponentVocals():FlxAudio {
        return vocals.members[0];
    }

    static function set_mainVocals(value:FlxAudio):FlxAudio {
        value.pitch = FlxG.timeScale;
        return vocals.members[1] = value;
    }

    static function set_opponentVocals(value:FlxAudio):FlxAudio {
        value.pitch = FlxG.timeScale;
        return vocals.members[0] = value;
    }

	// helper functions that im just gonna
	// throw at the bottom of here lmao
	inline public static function calculateCrotchet(bpm:Float) {
		return (60 / bpm) * 1000;
	}

    public static function getMeasureFromTime(timeAt:Float, ?useOffset:Bool = true):Float {
		var measureFromTime:Float = 0;
		var lastPointTime:Float = useOffset ? offset : 0;
		
        var curBPM:Float = timingPoints[0].bpm;
		var curPerMeasure:Float = timingPoints[0].beatsPerMeasure != 0 ? timingPoints[0].beatsPerMeasure : 4;

        for (point in timingPoints) {
			var pointTime:Float = (useOffset ? point.offsettedTime : point.time);
			if (timeAt >= pointTime) {
				measureFromTime += ((pointTime - lastPointTime) / calculateCrotchet(curBPM)) / curPerMeasure;
				lastPointTime = pointTime;

				curBPM = point.bpm != 0 ? point.bpm : curBPM;
				curPerMeasure = point.beatsPerMeasure != 0 ? point.beatsPerMeasure : curPerMeasure;
			} else break;
        }

        return measureFromTime;
    }

    public static function getBeatFromTime(timeAt:Float, ?useOffset:Bool = true):Float {
		var beatFromTime:Float = 0;
		var lastPointTime:Float = useOffset ? offset : 0;

        var curBPM:Float = timingPoints[0].bpm;

        for (point in timingPoints) {
			var pointTime:Float = (useOffset ? point.offsettedTime : point.time);
			if (timeAt >= pointTime) {
				beatFromTime += (pointTime - lastPointTime) / calculateCrotchet(curBPM);
				lastPointTime = pointTime;

				curBPM = point.bpm != 0 ? point.bpm : curBPM;
			} else break;
        }

        return beatFromTime;
    }

    public static function getPointFromTime(timeAt:Float, ?useOffset:Bool = true):TimingPoint {
        var lastPoint:TimingPoint = {};
        if (timingPoints.length == 0) return lastPoint;
		lastPoint = timingPoints[0];

        for (i => point in timingPoints) {
            if (timeAt >= (useOffset ? point.offsettedTime : point.time)) lastPoint = point;
            else break;
        }

        return lastPoint;
    }

	// got this method from troll engine, apperently it's stepmania's quantization method.
	public static function getQuantFromTime(timeAt:Float):Int {
		final point:TimingPoint = getPointFromTime(timeAt, false);
		var beat:Float = getBeatFromTime(timeAt, false);
		beat += (timeAt - point.time) / calculateCrotchet(point.bpm);

		final row:Int = Math.round(beat * 48); // 48 rows per beat
		for (quant in quants) {
			if (row % (192 / quant) == 0) // 192 rows per measure (48 * 4)
				return quant;
		}
		return quants[quants.length - 1];
	}
}
