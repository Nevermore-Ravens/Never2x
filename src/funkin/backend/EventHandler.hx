package funkin.backend;

import moonchart.formats.fnf.FNFGlobal;

class EventHandler {
    public dynamic function triggered(event:Event) {}
	public dynamic function pushed(event:Event) {}

	// just so it doesn't yell at me
	public function new() {}

    public var list:Array<Event> = [];
    public var index:ShortInt = 0;
    public function load(song:String, ?chart:Chart):EventHandler {
        // has to be "per song" instead
        // because of sm/osu support

		// edit 1/31/26: uhhhhh mustHitSections
		var foundEvents = false;
		var eventList:Array<Event> = [];

		// check if the chart is a json
		// if so
		// grab the mustHitSections from it and make events out of it
		// else just push one singular camera event

		// (how the FUCK do we do this
		// alright heres the plan -srt
		if (chart != null) {
			var chartEvents = chart.format.getEvents();
			for (ev in chartEvents) {
				if (FNFGlobal.isCamFocus(ev)) {
					var camTarget:Int = FNFGlobal.resolveCamFocus(ev);
					if (camTarget < 2)
						camTarget = 1 - camTarget; // player1 than player2 i get it but here at n2x we go left to right to back

					eventList.push({
						name: "Retarget Camera",
						time: ev.time,
						args: [camTarget]
					});
				} else {
					eventList.push({
						name: ev.name,
						time: ev.time,
						args: moonchart.backend.Util.resolveEventValues(ev)
					});
				}
			}

			foundEvents = eventList.length > 0;
		}
	
		// then parse the normal events file (if it exists
		if (Paths.exists('songs/$song/events.json')) {

			// god i love writing fuckass code that somehow works
			var data = Json5.parse(Paths.getFileContent('songs/$song/events.json'));
			var otherEvents:Array<Event> = [];

			var fuckassList:Array<{name:String, time:Float, args:Array<Dynamic>}> = data.list;
			for (event in fuckassList) {
				otherEvents.push({
					name: event.name,
					time: event.time,
					args: event.args
				});
			}

			// if events were parsed from the chart
			// concat the events.json to the chart events
			if (foundEvents) {
				eventList = eventList.concat(otherEvents);

			// else parse it as normal
			} else {
				eventList = otherEvents;
				foundEvents = true;
			}
		}

		// if no events were found whatsoever then just ignore it
        if (!foundEvents) return this;

        list.resize(0);

		for (i => event in eventList) {
			list.push(event);
			pushed(event);
        }

        index = 0;
		list.sort((a, b) -> return Std.int(a.time - b.time));

		return this;
    }

    public function update():Void {
        if (index >= list.length) return;

        final nextEvent:Event = list[index];
		if (nextEvent == null)return; // had a NOR where nextEvent was null, so

        if (nextEvent.time > Conductor.rawTime - Conductor.offset) return;
        triggered(nextEvent);
        index++;
    }
}

@:structInit 
class Event {
    public var name:String = '';
    public var time:Float = 0.0;
    public var args:Array<Dynamic> = [];

	public function toString():String {
		return 'Name: $name | Time: $time | Arguments: $args';
	}
}