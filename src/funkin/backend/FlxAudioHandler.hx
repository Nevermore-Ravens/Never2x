package funkin.backend;

import funkin.backend.audio.FlxAudio;
import flixel.group.FlxGroup.FlxTypedGroup;
import lime.utils.UInt8Array;

#if desktop
@:allow(funkin.backend.audio._backends.FlxOpenALSource)
#end
@:allow(funkin.backend.audio.FlxAudio)
class FlxAudioHandler
{
	public static var audioList:FlxTypedGroup<FlxAudio>;
	public static var soundList:FlxTypedGroup<FlxAudio>;

	public static var volume:Float;

	/**
	 * Variables to cache sounds in case the user doesn't use streaming and to speed up sound loading task (Only for native)
	 */
	private static var audioCache:Map<String, SoundBufferData>;

	public static var music:FlxAudio = null;

	public static function init() {
		music = new FlxAudio();
		audioList = new FlxTypedGroup<FlxAudio>();
		soundList = new FlxTypedGroup<FlxAudio>();
		audioCache = new Map();
	}

	public static function loadAudio(key:String = null, looped:Bool = false, volume:Float = 1, stream:Bool = true):FlxAudio
	{
		var audioStream:FlxAudio = new FlxAudio();

		audioStream.load(key, looped, stream);
		audioStream.volume = volume;

		audioStream.time = 0;

		return audioList.insert(0, audioStream);
	}

	public static function playMusic(key:String, looped:Bool = true, volume:Float = 1, stream:Bool = true):FlxAudio
	{
		if (music.path == key)
		{
			music.stop();
			music.volume = volume;
			music.looped = looped;
			music.time = 0;
		}
		else
			loadMusic(key, looped, stream);
	
		music.play();
		return music;
	}

	public static function loadMusic(key:String, looped:Bool = false, volume:Float = 1, stream:Bool = true):FlxAudio
	{
		music.load(key, looped, stream);
		music.volume = volume;
		music.time = 0;
		return music;
	}

	public static function checkStoredSounds()
	{
		for (al in audioList)
		{
			if (!al.exists) continue;
			al.destroy();
		}
		audioList.clear();

		for (key in audioCache.keys())
		{
			audioCache.get(key).onUse = false;
		}
	}

	public static function clearUnusedSounds()
	{
		#if desktop
		for (key in audioCache.keys())
		{
			if (audioCache.get(key).onUse || (music.path == key && !music.stopped))
				continue;
			//Debug.logInfo('removed cached sound $key');
			trace('removed cached sound $key');
			audioCache.remove(key);
		}
		#end
	}
}

class SoundBufferData
{
	public var bufferArray:UInt8Array;

	public var onUse:Bool = false;

	public function new(bufferArray:UInt8Array)
	{
		this.bufferArray = bufferArray;
		onUse = true;
	}

	public function dispose()
	{
		bufferArray = null;
	}
}
