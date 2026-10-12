package funkin.core.chart;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.Json;
import nevermore.Nevermore;
import nevermore.core.Assets;
import nevermore.core.Chart;
import nevermore.core.BaseParser;
//import nevermore.core.timing.ScrollVelocity;
import nevermore.core.Song;
import moonchart.backend.FormatData;
import moonchart.formats.*;
import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;
import moonchart.formats.BasicFormat;
import funkin.core.Addons;

// simple FormatDetector.instanceFromFiles() won't work here
// because any simfile/osu files will just default to the first strumline
// the only way as of right now to go around this is to parse the file and
// then convert it to fnf, and then back to the universal format
// then any files will default to the player's strumline
// because we don't normally have access to mustHitSection
// also side-note
// notice how v-slice takes up like a third of this entire class
//
// this is fucking stupid but whatever
class SongParser extends BaseParser {
	static var extensions:Array<String> = ['json', 'sm', 'ssc', 'osu', 'qua', 'chart'];

	override function exists(path:String, ?diff:String):Bool {
		return findInFolder(path, diff) != ""; // returns an empty string if it screwed up
	}

	override function load(path:String, ?diff:String):Chart {
		var result:Chart = Song.dummyData();
		var file:String = findInFolder(path, diff);

		if (file == "") return result;
		var path:Path = new Path(file);

		var fnf:FNFTroll = new FNFTroll();
		fnf.noteTypeResolver.register('Fake', 'StepMania Fake');
		fnf.noteTypeResolver.register('Mine', BasicNoteType.MINE);
		fnf.bakedOffset = false;
		fnf.offsetHolds = false;

		// we need to add the bpm changes from the original format directly
		// as fnf limits bpm changes to per-section, rather than being specific
		function addBPMChanges(meta:BasicMetaData) {
			for (bpm in meta.bpmChanges) {
				result.timingPoints.push({
					time: bpm.time,
					tempo: bpm.bpm,
					beatsPerMeasure: Std.int(bpm.beatsPerMeasure)
				});
			}
		}

		inline function addEvents(format:DynamicFormat) {
			for (ev in format.getEvents()) {
				var event = EventInterp.interpEvent(ev, result, format);
				if (event != null)
					result.events.push(event);
			}
		}

		switch path.ext {
			case 'chart':
				var gh = new GuitarHero().fromFile(file);
				var meta:BasicMetaData = gh.getChartMeta();
				addBPMChanges(meta);
				addEvents(gh);
				result.offset = meta.offset;

				fnf.fromFormat(gh);

				// some gh charts can be 4k/6k but
				// for the sake of simplicity
				// im doing 5k
				fnf.data.song.keyCount = 5;
			
			case 'json':
				// parse the file ourselves
				// because we need to check if it's v-slice or legacy
				var json = Json.parse(File.getContent(file));
				
				// legacy
				if (json.song != null) {
					fnf.data = cast json;
					fnf.data.song.events ??= [];
					addBPMChanges(fnf.getChartMeta());
					addEvents(fnf);

				} else if (json.codenameChart != null) {
					var meta = Json.parse(File.getContent(path.dir + '/codename-meta.json'));
					var codename = new FNFCodename(cast json, cast meta);

					fnf.fromFormat(codename);
					addBPMChanges(codename.getChartMeta());
					addEvents(codename);

				// v-slice/0.3.0+
				// fucking kill me dude this format sucks dick
				} else {
					var meta = Json.parse(File.getContent(path.dir + '/vslice-meta.json'));
					var vslice = new FNFVSlice(cast json, cast meta);
					vslice.diffs = [diff];

					fnf.fromFormat(vslice);
					addBPMChanges(vslice.getChartMeta());
					addEvents(vslice);
				}

			case 'sm':
				var sm = new CustomStepMania().fromFile(file);
				var meta:BasicMetaData = sm.getChartMeta();
				addBPMChanges(meta);
				addEvents(sm);
				result.offset = meta.offset;

				fnf.fromFormat(sm);

			case 'ssc':
				var ssc:CustomSSC = cast new CustomSSC().fromFile(file);
				var meta:BasicMetaData = ssc.getChartMeta();
				addBPMChanges(meta);
				addEvents(ssc);

				result.scrollVelocities = ssc.getScrollVelocities();
				result.offset = meta.offset;

				fnf.fromFormat(ssc);

			case 'qua':
				var qua:CustomQuaver = cast new CustomQuaver().fromFile(file);
				addBPMChanges(qua.getChartMeta());
				addEvents(qua);
				result.scrollVelocities = qua.getScrollVelocities();
				result.snapRelativeToChanges = false;

				fnf.fromFormat(qua);

			case 'osu':
				var osu:OsuMania = new OsuMania().fromFile(file);
				addBPMChanges(osu.getChartMeta());
				addEvents(osu);

				result.snapRelativeToChanges = false;

				fnf.fromFormat(osu);
		}

		// now we convert from fnf to the universal format
		// so [format] -> moonchart format -> fnf legacy -> universal format
		// what the fuck bro
		var fileMeta = fnf.getChartMeta();

		result.title = fileMeta.title;
		result.speed = fileMeta.scrollSpeeds.get(fnf.diffs[0]);
		
		result.keyCount = fnf.data.song.keyCount;
		if (result.keyCount == 0) result.keyCount = 4;

		for (section in fnf.data.song.notes) {
			for (note in section.sectionNotes) {
				result.notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % result.keyCount),
					length: note[2],
					player: note[1] > (result.keyCount - 1) != section.mustHitSection ? 1 : 0,
					type: note.type
				});
			}
		}

		return result;
	}

	static function findInFolder(folder:String, diff:String) {
		var directories:Array<String> = ['assets'];
		for (addon in Addons.list) {
			if (!addon.enabled) continue;
			directories.push('addons/${addon.directory}');
		}

		for (directory in directories) {
			var currentFolder:String = directory + '/' + folder;
			if (!FileSystem.exists(currentFolder)) continue;

			for (file in FileSystem.readDirectory(currentFolder)) {
				var path = new Path('$currentFolder/$file');

				if (!extensions.contains(path.ext)) continue;
				if (path.file != Util.format(diff)) continue;

				// this is probably the file we're looking for
				return path.toString();
			}
		}

		return '';
	}
}