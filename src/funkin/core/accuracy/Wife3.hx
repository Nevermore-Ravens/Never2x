package funkin.core.accuracy;

// https://github.com/etternagame/etterna/blob/develop/src/RageUtil/Utils/RageUtil.h#L96-154
// https://github.com/etternagame/etterna/blob/develop/src/Etterna/Actor/Gameplay/Player.cpp
//
// should be a direct port from the source (as of 0.75.1)
class Wife3 extends AccuracyHandler {
	var notesPlayed:Float = 0.0;
	var notesHit:Int = 0;
	public function new() {
		super(WIFE3);
	}

	public static final mineHitWeight:Float = -7.0;
	public static final holdDropWeight:Float = -4.5;
	public static final missWeight:Float = -5.0;

	// erf approximation A&S formula 7.1.26
	public static function werwerwerwerf(x:Float):Float {
		static final a1:Float = 0.254829592;
		static final a2:Float = -0.284496736;
		static final a3:Float = 1.421413741;
		static final a4:Float = -1.453152027;
		static final a5:Float = 1.061405429;
		static final p:Float = 0.3275911;

		var sign:Int = 1;
		if (x < 0) {
			sign = -1;
		}
		x = Math.abs(x);

		var t = 1.0 / (1.0 + p * x);
		var y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);

		return sign * y;
	}

	// ts is for when you change judgement levels
	// ie j4 -> j5, j6, j7, justice, etc
	// that's not a thing in fnf
	// (unless you're porting over the stuff yourself)
	// so by default we just use j4 (1)
	public static function calculate(maxms:Float, ?ts:Float):Float {
		ts ??= switch HitWindows.type {
			default: 1; // etterna limits judge scaling to j4 because        IDK

			case STEPMANIA_J5: 0.84;
			case STEPMANIA_J6: 0.66;
			case STEPMANIA_J7: 0.5;
			case STEPMANIA_J8: 0.33;
			case STEPMANIA_JUSTICE: 0.2;
		}

		// so judge scaling isn't so extreme
		static final jPow:Float = 0.75;

		// min/max points
		static final maxPoints:Float = 2.0;

		// offset at which points start decreasing(ms)
		var ridic:Float = 5.0 * ts;

		// technically the max boo is always 180ms above j4 however this is
		// immaterial to the end purpose of the scoring curve - assignment of point
		// values
		var maxBooWeight:Float = 180.0 * ts;

		// need positive values for this
		maxms = Math.abs(maxms);

		// case optimizations
		if (maxms <= ridic) {
			return maxPoints;
		}

		var zero:Float = 65.0 * Math.pow(ts, jPow);
		var dev:Float = 22.7 * Math.pow(ts, jPow);

		if (maxms <= zero) {
			return maxPoints * werwerwerwerf((zero - maxms) / dev);
		}

		if (maxms <= maxBooWeight) {
			return (maxms - zero) * missWeight / (maxBooWeight - zero);
		}

		return missWeight;
	}

	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();

		if (note.behavior.punishable) {
			notesPlayed += mineHitWeight;
		} else {
			notesPlayed += calculate(deviation);
			notesHit += 2;
		}
	}

	override function noteMissed(_) {
		notesPlayed += missWeight;
		notesHit += 2;
	}

	override function sustainDropped(_) {
		notesPlayed += holdDropWeight;
	}

	override function get(_):Float {
		if (notesPlayed <= 0.0) return 0.0;
		return (notesPlayed / notesHit) * 100;
	}
}