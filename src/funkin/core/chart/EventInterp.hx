package funkin.core.chart;

import nevermore.core.Chart;
import moonchart.formats.fnf.legacy.FNFLegacy;
import moonchart.formats.BasicFormat;
import moonchart.backend.Util;

/*
The intended conversion list currently:
	"Retarget Camera" => [target, ease, stepsDuration, xOffset, yOffset]
	"Zoom Camera" => [zoom, ease, stepsDuration, stageORdirect]
	"Bump Interval" => [interval, strength]
*/

class EventInterp {
	public static function interpEvent(event:BasicEvent, chart:Chart, format:DynamicFormat):ChartEvent {
		var name = event.name;
		var params:Array<Dynamic> = [];
		switch (event.name) {
			case FNFLegacy.FNF_LEGACY_MUST_HIT_SECTION_EVENT:
				name = "Retarget Camera";
				params = [event.data.mustHitSection ? 1 : 0, "CLASSIC"];

			case moonchart.formats.fnf.FNFCodename.CODENAME_CAM_MOVEMENT:
				name = "Retarget Camera";
				params = event.data.array;
				if (params.length > 1) {
					if (!params[1])
						params[2] = "INSTANT";
					params.splice(1, 1);

					var ease = getEase(params[2], params[3]); // combine the ease and easeDir into one
					params.splice(3, 1);

					params[2] = params[1]; // swap ease and duration
					params[1] = ease;
				} else
					params.push("CLASSIC");
			case "Camera Zoom":
				name = "Zoom Camera";
				params = event.data.array;
				if (params[2] == "camHUD")
					return null; // rather not
				params.splice(2, 1);

				if (!params.shift())
					params[2] = "INSTANT";

				var ease = getEase(params[2], params[3]); // combine the ease and easeDir into one
				params.splice(3, 1);

				params[2] = params[1]; // swap ease and duration
				params[1] = ease;
			case "Camera Modulo Change":
				name = "Bump Interval";
				params = event.data.array;

			case moonchart.formats.fnf.FNFVSlice.VSLICE_FOCUS_EVENT:
				event.data = expectFields(event.data, ["char", "duration", "ease", "easeDir", "x", "y"]);
				name = "Retarget Camera";
				params = Util.resolveEventValues(event);
				
				params[0] = params[0] < 2 ? 1 - params[0] : params[0]; // readjust the char param

				var ease = getEase(params[2], params[3]); // combine the ease and easeDir into one
				params.splice(3, 1);

				params[2] = params[1]; // swap ease and duration
				params[1] = ease;
			case "ZoomCamera":
				event.data = expectFields(event.data, ["duration", "ease", "easeDir", "mode", "zoom"]);
				name = "Zoom Camera";
				params = Util.resolveEventValues(event);
				params.insert(0, params.pop()); // zoom was the last argument, make it the first

				var ease = getEase(params[2], params[3]); // combine the ease and easeDir into one
				params.splice(3, 1);

				params[2] = params[1]; // swap ease and duration
				params[1] = ease;
			case "SetCameraBop":
				event.data = expectFields(event.data, ["intensity", "rate"]);
				name = "Bump Interval";
				params = Util.resolveEventValues(event);
				params = [params[1], params[0]]; // swap rate and intensity

			default:
				params = Util.resolveEventValues(event);
		}

		return {
			name: name,
			time: event.time,
			args: params
		};
	}

	static function getEase(ease:String, dir:String) {
		if (dir == null || ease == "CLASSIC" || ease == "INSTANT" || ease == "linear")
			return ease;
		return ease + dir;
	}

	// moonchart will sort arguments alphabetically, so any missing values may screw up arguments.
	static function expectFields(input:Dynamic, fields:Array<String>) {
		var result = {};
		if (Reflect.isObject(input)) {
			for (field in fields)
				Reflect.setField(result, field, Reflect.field(input, field));
		} else if (fields.length > 0) {
			Reflect.setField(result, fields[0], input);
			for (i in 1...fields.length)
				Reflect.setField(result, fields[i], null);
		}
		return result;
	}
}