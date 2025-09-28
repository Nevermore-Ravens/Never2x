package funkin.backend.audio._backends;

/**
 * Class for handling audio similar to NativeAudioSource.hx from Lime
 */
@:allow(funkin.backend.audio.FlxAudio)
class FlxAudioSource
{
	@:isVar
	public var time(get, set):Float;
	public var length(get, never):Float;
	public var pitch(get, set):Float;
	public var volume(get, set):Float;
	public var paused(get, never):Bool;
	public var stopped(get, never):Bool;
	public var playing(get, never):Bool;
	public var looped(get, set):Bool;

	private var connectedAudio:FlxAudio;
	private var completed:Bool = false;
	private var _playing:Bool = false;
	private var _looped:Bool = false;
	private var _stream:Bool = false;

	public function new(audio:FlxAudio)
	{
		this.connectedAudio = audio;
		init();
	}

	public function init():Void
	{
	}

	public function load(looped:Bool, stream:Bool):Void
	{
		stop();

		completed = false;
		_playing = false;

		_looped = looped;
		_stream = stream;
	}

	public function play():Void
	{
		completed = false;

		_playing = true;

		time = time;
		volume = volume;
	}

	public function pause():Void
	{
		_playing = false;
	}

	public function stop():Void
	{
		_playing = false;
		_looped = false;
		completed = true;

		@:bypassAccessor
		time = 0;
	}

	private function onEnd():Void
	{
		_playing = false;

		completed = true;

		if (looped)
			time = 0;

		if (connectedAudio.onComplete != null)
			connectedAudio.onComplete();

		if (looped)
			play();
	}

	public function dispose():Void
	{
		connectedAudio = null;
	}

	public function updateVolume():Void
	{
	}

	public function get_time():Float
		return 0.0;

	public function set_time(t:Float):Float
		return 0.0;

	public function get_length():Float
		return 0.0;

	public function get_pitch():Float
		return 1.0;

	public function set_pitch(p:Float):Float
		return 1.0;

	public function get_volume():Float
		return 0.0;

	public function set_volume(v:Float):Float
		return 0.0;

	public function get_playing():Bool
		return _playing;

	public function get_stopped():Bool
		return (!_playing && time == 0) || completed;

	public function get_paused():Bool
		return !_playing && !completed;

	public function get_looped():Bool
		return _looped;

	public function set_looped(b:Bool)
	{
		_looped = b;
		return b;
	}
}
