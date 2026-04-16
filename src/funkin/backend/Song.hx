package funkin.backend;

import moonchart.parsers.QuaverParser.QuaverHitObject;
#if SV_ALLOWED
import funkin.backend.Conductor.ScrollVelocity;
#end
import moonchart.formats.Quaver;
import haxe.io.Path;
import moonchart.formats.fnf.FNFVSlice;
import funkin.backend.Meta;
import funkin.objects.Note;
import funkin.objects.Strumline;
import moonchart.formats.OsuMania;
import moonchart.formats.StepMania;
import moonchart.formats.StepManiaShark;
import moonchart.formats.BasicFormat;

typedef JsonChart = {
	var notes:Array<JsonSection>;
	var speed:Float;
}
typedef JsonSection = {sectionNotes:Array<Dynamic>, mustHitSection:Bool, ?changeBPM:Bool, ?bpm:Float, ?sectionBeats:Float, ?lengthInSteps:Float};

typedef Chart = {
	var notes:Array<NoteData>;
	var speed:Float;
	var ?format:DynamicFormat;
	var ?meta:MetaFile;
}

interface ChartWithSVs {
	#if SV_ALLOWED
	public function getScrollVelocities(): Array<ScrollVelocity>;
	#end
}

class Song {
	public static function createDummyFile():Chart {
		return {
			notes: [],
			speed: 1.0
		}
	}

	public static function loadFromPath(path:String, ?meta:MetaFile):Chart {
		var file:Chart = createDummyFile();
		file.meta = meta;

		if (!FileSystem.exists(path)) return file;

		#if SV_ALLOWED
		Conductor.scrollVelocities = [
			{
				time: 0, visualPos: 0, multiplier: 1
			}
		];

		Conductor.setupSVs();
		#end

		inline function tryBpmChanges(basic:DynamicFormat, offsetMult:Float) {
			if (meta == null) return;
			if (meta.timingPoints != null && meta.timingPoints.length > 0) return;
			meta.timingPoints ??= [];

			final basicMeta = basic.getChartMeta();
			meta.offset = basicMeta.offset * offsetMult;
			for (bpm in basicMeta.bpmChanges) {
				meta.timingPoints.push({
					time: bpm.time,
					bpm: bpm.bpm,
					beatsPerMeasure: Std.int(bpm.beatsPerMeasure)
				});
			}
		}

		inline function trySVs(chart: ChartWithSVs){
			#if SV_ALLOWED
			Conductor.scrollVelocities = chart.getScrollVelocities();
			if (Conductor.scrollVelocities.length == 0)
				Conductor.scrollVelocities = [{}];
			Conductor.setupSVs();
			#end
		}

		Conductor.timingPointsResetQuants = false;

		var rawChart:JsonChart = switch haxe.io.Path.extension(path) {
			case 'json':
				var result:Dynamic = null;
				var json = Json.parse(File.getContent(path));
				if (json.scrollSpeed != null && json.version != null) {
					// VSLICE
					if (meta == null) {
						Sys.println("NOPE NOT PARSING VSLICE WITHOUT A META FILE");
						return file;
					}

					final diff = Path.withoutExtension(Path.withoutDirectory(path));
					var vslice = new FNFVSlice(cast json, {
						timeFormat: "ms",
						artist: "um",//meta.instComposer + " & " + meta.vocalComposer,
						charter: "um",//meta.charter.get(diff),
						generatedBy: "Never2x",
						version: "2.2.4",
						looped: false,
						playData: {
							album: "um",//meta.album,
							previewStart: 0,
							previewEnd: 5000,
							ratings: {},
							characters: {
								player: meta.player,
								girlfriend: meta.spectator,
								opponent: meta.opponent,

								// if this gives you compiler errors, you may need to update moonchart.
								instrumental: "", altInstrumentals: [],
								opponentVocals: [], playerVocals: []
							},
							difficulties: [diff],
							songVariations: [],
							noteStyle: "funkin",
							stage: meta.stage
						},
						songName: meta.songName,
						offsets: {
							instrumental: 0,
							vocals: {},
							altInstrumentals: {},
							altVocals: {}
						},
						timeChanges: [
							for (bpm in meta.timingPoints)
								{t: bpm.time, bpm: bpm.bpm, n: bpm.beatsPerMeasure, d: 4}
						]
					});
					vslice.diffs = [diff];
					file.format = vslice;
					var fnf:CamelliaChart = new CamelliaChart();
					fnf.bakedOffset = false;
					fnf.offsetHolds = false;
					result = fnf.fromFormat(vslice).data.song;
				} else {
					final form = new CamelliaChart();
					form.data = cast json;
					file.format = form;
					json = json.song;
					result = json;
				}

				if (meta != null && (meta.timingPoints == null || meta.timingPoints.length <= 0)) {
					meta.timingPoints ??= [];
					final sects:Array<JsonSection> = cast json.notes;

					var curTime:Float = 0;
					var curBpm = json.bpm;
					meta.timingPoints.push({
						time: curTime,
						bpm: curBpm,
						beatsPerMeasure: 4
					});
					for (section in sects) {
						if (section.changeBPM == true && (section.bpm ?? 0.0) > 0) { // using == true in case theres a null changeBPM
							curBpm = section.bpm;
							meta.timingPoints.push({
								time: curTime,
								bpm: curBpm,
								beatsPerMeasure: 4
							});
						}

						final len = section.sectionBeats ?? ((section.lengthInSteps ?? 16) * 0.25);
						curTime += Conductor.calculateCrotchet(curBpm) * len;
					}
				}
				cast result;

			case 'sm':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				var sm:StepMania = new StepMania().fromFile(path);
				file.format = sm;
				tryBpmChanges(sm, 1);
				cast fnf.fromFormat(sm).data.song;

			case 'ssc':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				var ssc:StepManiaShark = new StepManiaShark().fromFile(path);
				file.format = ssc;
				tryBpmChanges(ssc, 1);
				cast fnf.fromFormat(ssc).data.song;
			case 'qua':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				var quav:CamQuaver = cast new CamQuaver().fromFile(path);
				file.format = quav;
				tryBpmChanges(quav, 0);
				trySVs(quav);
				Conductor.timingPointsResetQuants = true;
				cast fnf.fromFormat(quav).data.song;
			case 'osu':
				var fnf:CamelliaChart = new CamelliaChart();
				fnf.bakedOffset = false;
				fnf.offsetHolds = false;
				final osu:CamOsuChart = cast new CamOsuChart().fromFile(path);
				file.format = osu;
				tryBpmChanges(osu, 0); // AudioLeadIn is NOT a song offset.
				cast fnf.fromFormat(osu).data.song;

			default: null;
		}

		for (section in rawChart.notes) {
			for (note in section.sectionNotes) {
				file.notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % 4),
					length: note[2],
					player: note[1] > (Strumline.keyCount - 1) != section.mustHitSection ? 1 : 0,
					speed: rawChart.speed,
					type: (note[3] is String ? note[3] : Note.defaultTypes[note[3]]) ?? '',
				});
			}
		}

		file.notes.sort((a, b) -> Std.int(a.time - b.time));

		return file;
	}

	public static function load(song:String, diff:String):Chart {
		return loadFromPath(Paths.get('songs/$song/${getFile(song, diff)}'), Meta.load(song));
	}

	static var formats:Array<String> = ['json', 'sm', 'ssc', 'qua', 'osu'];
	public static function getFile(song:String, diff:String) {
		diff = Difficulty.format(diff);
		var path:String = '$diff.${formats[0]}';

		var files:Array<String> = FileSystem.readDirectory(Paths.get('songs/$song'));
		for (format in formats) {
			if (files.contains('$diff.$format')) {
				path = '$diff.$format';
				break;
			}
		}

		return path;
	}

	public static function exists(song:String, difficulty:String):Bool {
		return Paths.exists('songs/$song/${getFile(song, difficulty)}');
	}
}

// Code from https://github.com/Quaver/Quaver.API/blob/master/Quaver.API/Maps/Qua.cs
// Not sure if this works as intended but oh well!
class CamQuaver extends Quaver implements ChartWithSVs {
	inline function getCommonBPM(){
		if(data.TimingPoints.length == 0)
			return 0.0;
		
		if(data.HitObjects.length == 0)
			return 0.0;

		var lastObject: QuaverHitObject = data.HitObjects[data.HitObjects.length - 1];
		var lastTime: Float =  lastObject.EndTime > 0 ? lastObject.EndTime : lastObject.StartTime;
		var durations: Map<String, Int> = []; // can't do float for some reason lol!!

		for(i in data.TimingPoints.length - 1 ... 0){
			var point = data.TimingPoints[i];
			
			if(point.StartTime > lastTime)
				continue;

			var duration: Int = cast lastTime - (i == 0 ? 0 : point.StartTime);
			lastTime = point.StartTime;

			var bpmString:String = Std.string(point.Bpm);

			if (!durations.exists(bpmString))
				durations.set(bpmString, duration);
			else
				durations.set(bpmString, durations.get(bpmString) + duration);
		}

		var durationsArray: Array<Array<Float>> = [];
		for(i => v in durations)
			durationsArray.push([Std.parseFloat(i), v]);

		durationsArray.sort((a, b) -> Std.int(b[1] - a[1]));

		return durationsArray.length == 0 ? data.TimingPoints[0].Bpm : durationsArray[0][0];
	}

	#if SV_ALLOWED
	public function getScrollVelocities(): Array<ScrollVelocity>{
		var vels: Array<ScrollVelocity> = [];
		if (data.BPMDoesNotAffectScrollVelocity == true){
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
		}else{
			var baseBpm: Float = getCommonBPM();
			
			var currentBpm: Float = data.TimingPoints[0].Bpm;
			var currentSv:Int = 0;
			var currentSvStartTime:Float = Math.NaN;
			var currentSvMult:Float = 1;
			var currentAdjustedSV:Float = Math.NaN;
			var initialSVMult:Float = Math.NaN;

			for(i in 0...data.TimingPoints.length){
				var timingPoint = data.TimingPoints[i];

				var nextHasSameStamp = i + 1 < data.TimingPoints.length && data.TimingPoints[i + 1].StartTime == timingPoint.StartTime;

				while(true){
					if (currentSv >= data.SliderVelocities.length)
						break;

					var sv = data.SliderVelocities[currentSv];

					if (sv.StartTime > timingPoint.StartTime)
						break;

					if (nextHasSameStamp && sv.StartTime == timingPoint.StartTime)
						break;

					if (sv.StartTime < timingPoint.StartTime) {
						// The way that osu! handles infinite BPM is more akin to "arbitrarily large SV".
						// We chose the smallest power of two greater than `MAX_MULTIPLIER`
						// from `SVFactor` to make `DenormalizeSVs` more accurate.
						var multiplier = !Math.isFinite(currentBpm) ? 128 : sv.Multiplier * (currentBpm / baseBpm);

						if (Math.isNaN(currentAdjustedSV)) {
							currentAdjustedSV = multiplier;
							initialSVMult = multiplier;
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

					currentSvStartTime = sv.StartTime;
					currentSvMult = sv.Multiplier;
					currentSv += 1;
				}

				if (Math.isNaN(currentSvStartTime) || currentSvStartTime < timingPoint.StartTime)
					currentSvMult = 1;

				currentBpm = timingPoint.Bpm;

				var multToo = !Math.isFinite(currentBpm) ? 128 : currentSvMult * (currentBpm / baseBpm);

				if (Math.isNaN(currentAdjustedSV)) {
					currentAdjustedSV = multToo;
					initialSVMult = multToo;
				}

				if (multToo == currentAdjustedSV)
					continue;

				vels.push({
					time: timingPoint.StartTime,
					multiplier: multToo
				});

				currentAdjustedSV = multToo;
			}

			for(i in 0...data.SliderVelocities.length){
				currentSv = i;
				var sv = data.SliderVelocities[currentSv];
				var multiplier = !Math.isFinite(currentBpm) ? 128 : sv.Multiplier * (currentBpm / baseBpm);

				if (multiplier == currentAdjustedSV)
					continue;

				vels.push({
					time: sv.StartTime,
					multiplier: multiplier
				});

				currentAdjustedSV = multiplier;
			}

			if (!Math.isNaN(initialSVMult)){
				vels.push({
					time: 0,
					multiplier: initialSVMult
				});

			}

		}

		vels.sort((a, b) -> Std.int(a.time - b.time));

		return vels;
	}
	#end
	
}



class CamOsuChart extends OsuMania {
	public static function encodeType(hitsound:ByteInt) {
		return 'OSU__$hitsound';
	}

	override function getNotes(?diff:String):Array<BasicNote> {
		var circleSize:Int = data.Difficulty.CircleSize;
		var hitObjects = data.HitObjects;
		var notes:Array<BasicNote> = moonchart.backend.Util.makeArray(hitObjects.length);

		for (i in 0...hitObjects.length) {
			var note = hitObjects[i]; // x, y, time, type, hitSound, objectParams, length/hitSample
			var time:Int = note[2];
			var lane:Int = Math.floor(note[0] * circleSize / OsuMania.OSU_CIRCLE_SIZE);
			var length:Int = (note[5] > 0) ? (note[5] - time) : 0;

			var foundType = note[3];
			var type = BasicNoteType.DEFAULT;

			if (note[4] != 0)
				type = encodeType(note[4]);

			moonchart.backend.Util.setArray(notes, i, {
				time: time,
				lane: lane,
				length: length,
				type: type
			});
		}

		moonchart.backend.Timing.sortNotes(notes);

		return notes;
	}
}

class CamelliaChart extends moonchart.formats.fnf.legacy.FNFLegacy {
 	public function new() {
    	this.indexedTypes = false;
    	this.bakedOffset = false;
    	this.offsetHolds = false;
    
    	super();
		noteTypeResolver.register("Roll", BasicNoteType.ROLL);
		noteTypeResolver.register("Mine", BasicNoteType.MINE);
		noteTypeResolver.register('Cheer', CamOsuChart.encodeType(4));
		noteTypeResolver.register("Alt Animation", CamOsuChart.encodeType(8));
    	noteTypeResolver.register("this is a duel note", CamOsuChart.encodeType(10));
		noteTypeResolver.register("this is a uufo only note", CamOsuChart.encodeType(2));
  	}
}