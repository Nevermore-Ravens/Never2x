package funkin.modchart.timeline;

import funkin.modchart.BaseModifier;
import funkin.modchart.ModchartManager.ModRedirect;
import funkin.modchart.timeline.BaseEvent;

class FuncEvent extends BaseEvent {
    public var length:Float;
    public var ease:Float->Float;

    public var func:Float->Float->Void;

    public function new(beat:Float, length:Float, func:Float->Float->Void, ?ease:Float->Float) {
        this.instant = length <= 0;

        this.beat = beat;
        this.length = length;
        this.ease = ease != null ? ease : FlxEase.linear;
        this.func = func;
    }

    override function start() {
        if (instant)
            func(1, beat);
    }

    override function tick(curBeat:Float) {
        var percent = Math.min((curBeat - beat) / length, 1);
        percent = ease(percent);

        func(percent, curBeat);
    }

    override function canFinish(curBeat:Float) {
        return curBeat - beat >= length;
    }
}