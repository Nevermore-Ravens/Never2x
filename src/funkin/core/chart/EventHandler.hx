package funkin.core.chart;

import haxe.Constraints.Function;
import nevermore.core.timing.BaseClock;
import nevermore.core.Chart;

class EventHandler {
	public var list:Array<ChartEvent>;
	public var index:Int = 0;

	var _prepHandlers:Map<String, ChartEvent->Bool->Void> = [];
	var _handlers:Map<String, Function> = []; // these will directly be called with the arguments ([6, "str", false] -> func(6, "str", false))

	public dynamic function prepare(event:ChartEvent, first:Bool):Void {}
	public dynamic function triggered(event:ChartEvent):Void {}

	public function attachPreperation(name:String, func:ChartEvent->Bool->Void, ?replace:Bool = false) {
		if (replace || !_prepHandlers.exists(name))
			_prepHandlers.set(name, func);
		else {
			var oldFunc:ChartEvent->Bool->Void = _prepHandlers.get(name);
			_prepHandlers.set(name, function(ev, first) {
				oldFunc(ev, first);
				func(ev, first);
			});
		}
	}

	public function registerEvent(name:String, func:Function, ?replace:Bool = true) {
		if (replace || !_handlers.exists(name))
			_handlers.set(name, func);
		else {
			var oldFunc:Function = _handlers.get(name);
			_handlers.set(name, Reflect.makeVarArgs(args -> {
				Reflect.callMethod(null, oldFunc, args);
				Reflect.callMethod(null, func, args);
			}));
		}
	}

	public function load(from:Chart) {
		list = from.events; // this may become a copy instead of a reference in the future but

		var loadedTypes:Array<String> = [];
		for (ev in list) {
			var first = loadedTypes.contains(ev.name);
			if (first)
				loadedTypes.push(ev.name);

			if (_prepHandlers.exists(ev.name))
				_prepHandlers[ev.name](ev, first);
			prepare(ev, first);
		}

		list.sort((a, b) -> return Std.int(a.time - b.time));
	}

	public function update(clock:BaseClock) {
		while (index < list.length) {
			var event:ChartEvent = list[index];
			if (clock.time < event.time) break;

			if (_handlers.exists(event.name))
				Reflect.callMethod(null, _handlers.get(event.name), event.args);
			triggered(event);
			index++;
		}
	}

	public function new() {}
}