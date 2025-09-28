package funkin.backend.audio;

import funkin.backend.audio._backends.FlxAudioSource;
#if sys
import funkin.backend.audio._backends.FlxOpenALSource;
#end

/**
 * Replacement of FlxSound that gets rid of openfl Sound to expose cut features such as streaming (only in native) and see streamed bytes in real time.
 * 
 * In Native: Streaming and smart caching support
 * 
 * In HTML5: No differences with FlxSound, this is because the game needs to load the entire library and caching it to the ram including sounds, so streaming and caching doesn't make sense here.
 * 
 * @author BoloVEVO
 */
@:allow(backend.FlxAudioHandler)
class FlxAudio extends FlxBasic {
	private var _audioBackend:FlxAudioSource;
	public var time(get, set):Float;
	public var length(get, never):Float;
	public var pitch(get, set):Float;
	public var volume(get, set):Float;
	public var paused(get, never):Bool;
	public var stopped(get, never):Bool;
	public var playing(get, never):Bool;
	public var looped(get, set):Bool;

	public var onComplete:Void->Void;

	public var path:String;

	public function new()
	{
		super();
		_audioBackend = new FlxOpenALSource(this);
	}

	public function load(audioPath:Null<String>, looped:Bool = false, stream:Bool = false):FlxAudio
	{
		path = audioPath;

		#if sys
		stream = stream && funkin.backend.Settings.data.audioStreams;
		if (!stream && FlxAudioHandler.audioCache.exists(path))
		{
			var openALBackend:FlxOpenALSource = cast(_audioBackend, FlxOpenALSource);
			var bufferData = FlxAudioHandler.audioCache.get(path);
			bufferData.onUse = true;
			openALBackend.loadFromBuffer(bufferData.bufferArray, looped);
		}
		else
		{
			_audioBackend.load(looped, stream);
		}
		#else
		_audioBackend.load(looped, stream);
		#end

		return this;
	}

	public function get_looped()
		return _audioBackend.looped;

	public function set_looped(t:Bool)
	{
		_audioBackend.looped = t;
		return t;
	}

	public function get_time()
		return _audioBackend.time;

	public function set_time(t:Float)
	{
		_audioBackend.time = t;
		return t;
	}

	public function get_length()
		return _audioBackend.length;

	public function get_pitch()
		return _audioBackend.pitch;

	public function set_pitch(p:Float)
	{
		_audioBackend.pitch = p;
		return p;
	}

	public function get_volume()
		return _audioBackend.volume;

	public function set_volume(v:Float)
	{
		_audioBackend.volume = v;
		return v;
	}

	public function get_paused()
		return _audioBackend.paused;

	public function get_stopped()
		return _audioBackend.stopped;

	public function play()
		_audioBackend.play();

	public function pause()
		_audioBackend.pause();

	public function stop()
		_audioBackend.stop();

	public function get_playing()
		return _audioBackend.playing;

	override function destroy()
	{
		onComplete = null;
		super.destroy();
		_audioBackend.connectedAudio = null;
		_audioBackend.dispose();
	}
}
