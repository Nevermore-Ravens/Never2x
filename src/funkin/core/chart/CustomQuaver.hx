package funkin.core.chart;

import nevermore.core.timing.ScrollVelocity;
import moonchart.formats.Quaver;
import moonchart.parsers.QuaverParser;

class CustomQuaver extends Quaver {
	inline function getCommonBPM(){
		if (data.TimingPoints.length == 0) return 0.0;
		if (data.HitObjects.length == 0) return 0.0;

		var lastObject:QuaverHitObject = data.HitObjects[data.HitObjects.length - 1];
		var lastTime:Float =  lastObject.EndTime > 0 ? lastObject.EndTime : lastObject.StartTime;
		var durations:Map<String, Int> = []; // can't do float for some reason lol!!

		for (i in data.TimingPoints.length - 1 ... 0) {
			var point = data.TimingPoints[i];
			
			if (point.StartTime > lastTime)
				continue;

			var duration:Int = cast lastTime - (i == 0 ? 0 : point.StartTime);
			lastTime = point.StartTime;

			var bpmString:String = Std.string(point.Bpm);

			if (!durations.exists(bpmString))
				durations.set(bpmString, duration);
			else
				durations.set(bpmString, durations.get(bpmString) + duration);
		}

		var durationsArray:Array<Array<Float>> = [];
		for (i => v in durations)
			durationsArray.push([Std.parseFloat(i), v]);

		durationsArray.sort((a, b) -> Std.int(b[1] - a[1]));

		return durationsArray.length == 0 ? data.TimingPoints[0].Bpm : durationsArray[0][0];
	}

	public function getScrollVelocities():Array<ScrollVelocity> {
		var vels:Array<ScrollVelocity> = [];
		if (data.BPMDoesNotAffectScrollVelocity == true) {
			vels.push({
				time: 0,
				multiplier: data.InitialScrollVelocity
			});
			if (data.SliderVelocities.length > 0) {
				for (sv in data.SliderVelocities) {
					vels.push({
						time: sv.StartTime,
						multiplier: sv.Multiplier
					});
				}
			}
		} else {
			var baseBpm:Float = getCommonBPM();
			
			var currentBpm:Float = data.TimingPoints[0].Bpm;
			var current:Int = 0;
			var currentStartTime:Float = Math.NaN;
			var currentMult:Float = 1;
			var currentAdjustedSV:Float = Math.NaN;
			var initialMult:Float = Math.NaN;

			for (i in 0...data.TimingPoints.length) {
				var timingPoint = data.TimingPoints[i];

				var nextHasSameStamp = i + 1 < data.TimingPoints.length && data.TimingPoints[i + 1].StartTime == timingPoint.StartTime;

				while (true) {
					if (current >= data.SliderVelocities.length) break;

					var sv = data.SliderVelocities[current];
					if (sv.StartTime > timingPoint.StartTime) break;
					if (nextHasSameStamp && sv.StartTime == timingPoint.StartTime) break;

					if (sv.StartTime < timingPoint.StartTime) {
						// The way that osu! handles infinite BPM is more akin to "arbitrarily large SV".
						// We chose the smallest power of two greater than `MAX_MULTIPLIER`
						// from `SVFactor` to make `DenormalizeSVs` more accurate.
						var multiplier = !Math.isFinite(currentBpm) ? 128 : sv.Multiplier * (currentBpm / baseBpm);

						if (Math.isNaN(currentAdjustedSV)) {
							currentAdjustedSV = multiplier;
							initialMult = multiplier;
						}

						// ReSharper disable once CompareOfFloatsByEqualityOperator
						if (multiplier != currentAdjustedSV) {
							vels.push({
								time: sv.StartTime,
								multiplier: multiplier
							});
							//normalizedScrollVelocities.Add(new SliderVelocityInfo {StartTime = sv.StartTime, Multiplier = multiplier});

							currentAdjustedSV = multiplier;
						}
					}

					currentStartTime = sv.StartTime;
					currentMult = sv.Multiplier;
					current++;
				}

				if (Math.isNaN(currentStartTime) || currentStartTime < timingPoint.StartTime)
					currentMult = 1;

				currentBpm = timingPoint.Bpm;

				var multToo = !Math.isFinite(currentBpm) ? 128 : currentMult * (currentBpm / baseBpm);

				if (Math.isNaN(currentAdjustedSV)) {
					currentAdjustedSV = multToo;
					initialMult = multToo;
				}

				if (multToo == currentAdjustedSV) continue;

				vels.push({
					time: timingPoint.StartTime,
					multiplier: multToo
				});

				currentAdjustedSV = multToo;
			}

			for (i in 0...data.SliderVelocities.length) {
				current = i;
				var sv = data.SliderVelocities[current];
				var multiplier = !Math.isFinite(currentBpm) ? 128 : sv.Multiplier * (currentBpm / baseBpm);

				if (multiplier == currentAdjustedSV) continue;

				vels.push({
					time: sv.StartTime,
					multiplier: multiplier
				});

				currentAdjustedSV = multiplier;
			}

			if (!Math.isNaN(initialMult)) {
				vels.push({
					time: 0,
					multiplier: initialMult
				});
			}
		}

		//vels.sort((a, b) -> Std.int(a.time - b.time));
		return vels;
	}
}