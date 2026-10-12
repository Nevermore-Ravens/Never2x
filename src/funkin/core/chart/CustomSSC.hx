package funkin.core.chart;

import nevermore.core.timing.ScrollVelocity;
import moonchart.formats.StepManiaShark;
import moonchart.formats.StepMania;
import moonchart.formats.BasicFormat;
import moonchart.backend.Timing;

// for adding support for sv's
class CustomSSC extends StepManiaShark {
	override function getBpmChanges():Array<BasicBPMChange> {
		var BPMS = data.BPMS;
		var bpmChanges:Array<BasicBPMChange> = moonchart.backend.Util.makeArray(BPMS.length);

		var time:Float = 0;
		var lastBeat:Float = BPMS[0].beat;
		var lastBPM:Float = BPMS[0].bpm;

		var stopIndex = 0;
		var delayIndex = 0;
		var warpIndex = 0;
		while (warpIndex < data.WARPS.length && lastBeat >= data.WARPS[warpIndex].beat)
			lastBeat += data.WARPS[warpIndex++].beat_duration;

		moonchart.backend.Util.setArray(bpmChanges, 0, {
			time: 0,
			bpm: lastBPM,
			beatsPerMeasure: 4,
			stepsPerBeat: 4
		});

		// Convert the bpm changes from beats to milliseconds
		for (i in 1...BPMS.length) {
			var change = BPMS[i];
			var nextBeat = change.beat > lastBeat ? change.beat : lastBeat;
			time += ((nextBeat - lastBeat) / lastBPM) * 60000;

			lastBeat = nextBeat;
			lastBPM = change.bpm;

			moonchart.backend.Util.setArray(bpmChanges, i, {
				time: time,
				bpm: lastBPM,
				beatsPerMeasure: 4,
				stepsPerBeat: 4
			});

			while (delayIndex < data.DELAYS.length && lastBeat >= data.DELAYS[delayIndex].beat)
				time += data.DELAYS[delayIndex++].secs_duration * 1000;
			while (stopIndex < data.STOPS.length && lastBeat >= data.STOPS[stopIndex].beat)
				time += data.STOPS[stopIndex++].duration * 1000;
			while (warpIndex < data.WARPS.length && lastBeat >= data.WARPS[warpIndex].beat)
				lastBeat += data.WARPS[warpIndex++].beat_duration;
		}

		bpmChanges = Timing.sortBPMChanges(bpmChanges);
		return bpmChanges;
	}

	public function getScrollVelocities():Array<ScrollVelocity> {
		var bpms = getBpmChanges();
		var curBpm = 0;
		var checkpointTime = bpms[curBpm].time;
		var checkpointBeat = data.BPMS[curBpm].beat;
	
		var timeOffset = 0.0;
		var stopIndex = 0;
		var delayIndex = 0;
		var warpIndex = 0;
		var warpOffset = 0.0;

		var result:Array<ScrollVelocity> = [];
		for (scroll in data.SCROLLS) {
			while (curBpm < bpms.length - 1 && data.BPMS[curBpm + 1].beat <= scroll.beat) {
				++curBpm;
				checkpointTime = bpms[curBpm].time;
				checkpointBeat = data.BPMS[curBpm].beat;

				while (warpIndex < data.WARPS.length && data.BPMS[curBpm].beat >= data.WARPS[warpIndex].beat) {
					final warp = data.WARPS[warpIndex++];
					checkpointBeat = Math.max(checkpointBeat, warp.beat + warp.beat_duration);
				}
			}

			// Do warps between steps (please workl)
			while (warpIndex < data.WARPS.length && scroll.beat >= data.WARPS[warpIndex].beat)
				warpOffset += data.WARPS[warpIndex++].beat_duration;

			// Do Delays between steps, but apply the timeshift before instead of after.
			while (delayIndex < data.DELAYS.length && scroll.beat >= data.DELAYS[delayIndex].beat)
				timeOffset += data.DELAYS[delayIndex++].secs_duration * 1000;

			result.push({
				time: checkpointTime + Math.max((scroll.beat - checkpointBeat) - warpOffset, 0) * (60000 / bpms[curBpm].bpm) + timeOffset,
				multiplier: scroll.scroll
			});

			// Do Stops between steps
			while (stopIndex < data.STOPS.length && scroll.beat >= data.STOPS[stopIndex].beat)
				timeOffset += data.STOPS[stopIndex++].duration * 1000;
		}

		if (result.length <= 0 || result[0].time > 1)
			result.insert(0, {time: 0, multiplier: 1});

		return result;
	}
}