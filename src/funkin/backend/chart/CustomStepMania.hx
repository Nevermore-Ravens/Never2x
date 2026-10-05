package funkin.backend.chart;

import moonchart.formats.BasicFormat;
import moonchart.formats.StepMania;
import moonchart.backend.Timing;

// for adding support for fakes
// (line 74)
class CustomStepMania extends StepMania {
	override function getNotes(?diff:String):Array<BasicNote> {
		diff ??= moonchart.backend.Util.mapFirstKey(data.NOTES);

		var smChart = data.NOTES.get(diff);
		if (smChart == null) {
			throw "Couldn't find StepMania notes for difficulty " + diff;
			return null;
		}

		var smNotes = smChart.notes;
		var notes:Array<BasicNote> = [];

		var bpms = data.BPMS;
		var bpmIndex:Int = 1;

		var stops = data.STOPS;
		var stopIndex:Int = 0;

		var bpm = bpms[0].bpm;
		var beat:Float = bpms[0].beat;
		var time:Float = beat * Timing.crochet(bpm);

		final getStepCrochet = (snap:Int) -> return Timing.snappedStepCrochet(bpm, 4, snap);
		final holdIndexes:Array<Int> = [for (i in 0...smChart.dance.len()) -1];

		for (measure in smNotes) {
			var steps:Int = measure.length;
			var beatsPerStep = 4.0 / steps;
			var stepCrochet = getStepCrochet(steps);

			for (step in measure) {
				// Do BPM changes and sum BPM intervals between steps
				while (bpmIndex < bpms.length && beat >= bpms[bpmIndex].beat) {
					// Calculate interval between BPM changes
					final bpmChange = moonchart.backend.Util.getArray(bpms, bpmIndex);
					var nextBeat = bpmChange.beat;
					var remainingBeats = nextBeat - beat;
					time += remainingBeats * Timing.crochet(bpm);
					time -= remainingBeats * Timing.crochet(bpmChange.bpm);

					// Update the rest of the crap
					bpm = bpmChange.bpm;
					stepCrochet = getStepCrochet(steps);
					bpmIndex++;
				}

				// Check for the current step notes
				for (lane in 0...step.length) {
					switch (step.fastCodeAt(lane)) {
						case EMPTY:
						case NOTE:
							notes.push({
								time: time,
								lane: lane,
								length: 0,
								type: ""
							});
						case MINE:
							notes.push({
								time: time,
								lane: lane,
								length: 0,
								type: BasicNoteType.MINE
							});
						case "F".code:
							notes.push({
								time: time,
								lane: lane,
								length: 0,
								type: 'StepMania Fake'
							});
						case HOLD_HEAD:
							notes.push({
								time: time,
								lane: lane,
								length: stepCrochet,
								type: ""
							});
							holdIndexes[lane] = notes.length - 1;
						case ROLL_HEAD:
							notes.push({
								time: time,
								lane: lane,
								length: stepCrochet,
								type: BasicNoteType.ROLL
							});
							holdIndexes[lane] = notes.length - 1;
						case HOLD_TAIL:
							if (holdIndexes[lane] != -1)
							{
								notes[holdIndexes[lane]].length = time - notes[holdIndexes[lane]].time;
								holdIndexes[lane] = -1;
							}
						case _:
					}
				}

				time += stepCrochet;
				beat += beatsPerStep;

				// Do Stops between steps
				while (stopIndex < stops.length && beat >= stops[stopIndex].beat) {
					time += stops[stopIndex++].duration * 1000;
				}
			}
		}

		return notes;
	}
}