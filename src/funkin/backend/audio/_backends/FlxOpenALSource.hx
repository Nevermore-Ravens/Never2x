package funkin.backend.audio._backends;

import haxe.Int64;
import haxe.Timer;
import lime.media.AudioManager;
import lime.media.OpenALAudioContext;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.vorbis.VorbisFile;
import lime.media.vorbis.VorbisInfo;
import lime.utils.UInt8Array;
import funkin.backend.FlxAudioHandler;

/**
 * Audio backend for Native that supports OpenAL
 */
@:allow(backend.audio.FlxAudio)
class FlxOpenALSource extends FlxAudioSource
{
	// Vorbis file
	public var vorb:VorbisFile;

	// Vorbis file Info
	var vorbInfo:VorbisInfo;

	private var _length:Float = 10.0;

	// DEFAULT BUFFER SIZE PER 100MS CHECK FOR STREAMING
	static final STREAM_TIMER_CHECK_MS:Int = 100;

	static final STREAM_BUFFER_SIZE:Int = 48000;

	// MAIN OPENAL SOURCE
	private var openALSource:ALSource;

	// MAIN OPENAL BUFFER USED TO CACHED SOUND (NOT FOR STREAMING)
	private var openALBuffer:ALBuffer;

	// APPROACH OF 3 BUFFERS FOR STREAMING (0 - CURRENT , 1 - NEXT, 2 - STANDBY)
	var buffers:Array<ALBuffer>;

	var bufferTimeBlocks:Array<Float>; // Time stamp of the buffers, has the same order as buffers

	var vorbisBufferDatas:Array<UInt8Array>; // Unsigned Array of the audio data to stream

	var queuedBuffers:Int = 0;

	/**
	 * TODO: Turn Haxe Timers into FlxTimers, initializing them takes performance!
	 */
	// STREAM TIMER TO CHECK FOR AVAILABLE AUDIO DATA EACH 100MS
	var streamTimer:Timer;

	// Timer that waits audio completion
	var completeTimer:Timer;

	var initializedBuffers:Bool = false;

	var audioContext:OpenALAudioContext = null;

	var _audioDataLength:Int;

	var _sampleLength:Int;

	var _volume:Float = 1.0;

	override function init()
	{
		if (AudioManager.context == null)
			AudioManager.init();

		audioContext = AudioManager.context.openal;

		buffers = new Array();
		bufferTimeBlocks = new Array();
		vorbisBufferDatas = new Array();

		for (i in 0...3)
		{
			buffers[i] = audioContext.createBuffer();
			bufferTimeBlocks[i] = 0;
			vorbisBufferDatas[i] = new UInt8Array(STREAM_BUFFER_SIZE); // Better to instantiate them here instead of making a new instance per buffer
		}

		openALSource = audioContext.createSource();

		// Override native openAL looping
		audioContext.sourcei(openALSource, audioContext.LOOPING, false);

		openALBuffer = audioContext.createBuffer();
	}

	override function load(looped:Bool, stream:Bool)
	{
		super.load(looped, stream);

		for (i in 0...3)
		{
			bufferTimeBlocks[i] = 0;
		}

		if (vorb != null)
		{
			vorb.clear();
			vorb = null;
		}

		if (vorbInfo != null)
		{
			vorbInfo = null;
		}

		//var desiredPath:String = '';

		try
		{
			//desiredPath = OpenFlAssets.getPath(connectedAudio.path);
			vorb = VorbisFile.fromFile(/*desiredPath*/connectedAudio.path); //i had to do this since openfl can't find foreign files
		}
		catch (e)
		{
			//Debug.logWarn('Audio ${connectedAudio.path} couldnt be loaded because the sound ogg couldnt be found!');
			trace('Audio ${connectedAudio.path} couldnt be loaded because the sound ogg couldnt be found!');
			return;
		}

		if (vorb == null)
			return;

		vorbInfo = vorb.info();

		_length = vorb.timeTotal() * 1000;

		_audioDataLength = Std.int(vorbInfo.rate * vorbInfo.channels * 16 * vorb.timeTotal() / 8);
		_sampleLength = Int64.toInt(vorb.pcmTotal());

		if (!stream)
		{
			var soundData:UInt8Array = readVorbisFileBuffer(vorb, audioContext);
			var bufferData:SoundBufferData = new SoundBufferData(soundData);
			FlxAudioHandler.audioCache.set(connectedAudio.path, bufferData);

			var vorbChannels = audioContext.FORMAT_STEREO16;
			if (vorbInfo.channels <= 1)
				vorbChannels = audioContext.FORMAT_MONO16;

			audioContext.bufferData(openALBuffer, 0, null, 0, 0);

			audioContext.sourcei(openALSource, audioContext.BUFFER, null);

			audioContext.bufferData(openALBuffer, vorbChannels, soundData, soundData.length, vorbInfo.rate);

			audioContext.sourcei(openALSource, audioContext.BUFFER, openALBuffer);
		}

		// Debug.logInfo('loaded ${connectedAudio.path}');

		initializedBuffers = false;
	}

	override function get_length():Float
	{
		return _length;
	}

	override inline function get_volume():Float
	{
		if (openALSource != null)
			return _volume;

		return 1.0;
	}

	override inline function set_volume(newVol:Float):Float
	{
		_volume = newVol;

		updateVolume();

		return newVol;
	}

	override function updateVolume()
	{
		if (FlxG.sound.muted)
			audioContext.sourcef(openALSource, audioContext.GAIN, 0);
		else
			audioContext.sourcef(openALSource, audioContext.GAIN, _volume * FlxAudioHandler.volume);
	}

	override function play()
	{
		if (vorb == null)
			return;

		initializedBuffers = true;

		super.play();

		if (!_stream)
		{
			audioContext.sourcePlay(openALSource);
		}
	}

	function bufferStream_task()
	{
		if (openALSource == null || vorb == null || completed)
			return;

		var newBuffers = dequeueBuffers();

		queueNewBuffers(newBuffers);
	}

	private function dequeueBuffers():Array<ALBuffer>
	{
		if (openALSource == null || vorb == null)
			return null;

		var buffersProcessed:Int = audioContext.getSourcei(openALSource, audioContext.BUFFERS_PROCESSED);

		var buffers:Array<ALBuffer> = null;

		if (buffersProcessed > 0)
		{
			queuedBuffers -= buffersProcessed;
			if (buffersProcessed > 1) // Program freezed or a lag spike occured and the main buffer is already processed so we need to update the complete timer
				updateCompleteTimer();
			var position = Int64.toInt(vorb.pcmTell());
			if (position < _audioDataLength)
				buffers = audioContext.sourceUnqueueBuffers(openALSource, buffersProcessed);
		}

		initializedBuffers = true;

		return buffers;
	}

	private function queueNewBuffers(buffers:Array<ALBuffer>)
	{
		if (openALSource == null || vorb == null || buffers == null)
			return;

		var position = Int64.toInt(vorb.pcmTell());

		if (buffers != null)
		{
			var soundData:UInt8Array = null;

			var vorbFormat = audioContext.FORMAT_STEREO16;
			var vorbInfo = vorb.info();
			if (vorbInfo.channels <= 1)
				vorbFormat = audioContext.FORMAT_MONO16;
			var numBuffers:Int = 0;
			for (buffer in buffers)
			{
				if (position >= _sampleLength)
				{
					// End reached, no more buffers but audio still not ended??
					// We fake the time increase then
					for (i in 0...2)
					{
						bufferTimeBlocks[i] = bufferTimeBlocks[i + 1];
						vorbisBufferDatas[i] = vorbisBufferDatas[i + 1];
					}

					bufferTimeBlocks[2] += (FlxG.elapsed * 1000) * pitch;

					break;
				}

				soundData = readVorbisBufferStream(vorb, STREAM_BUFFER_SIZE);

				position += soundData.length;

				audioContext.bufferData(buffer, vorbFormat, soundData, soundData.length, vorbInfo.rate);

				numBuffers++;
			}

			queuedBuffers = numBuffers;

			audioContext.sourceQueueBuffers(openALSource, numBuffers, buffers);
			// Debug.logInfo('$key: BUFFERS QUEUED ${audioContext.getSourcei(audioSource, audioContext.BUFFERS_QUEUED)}');
		}

		if (playing && openALSource != null && audioContext.getSourcei(openALSource, audioContext.SOURCE_STATE) == audioContext.STOPPED)
		{
			audioContext.sourcePlay(openALSource);
		}
	}

	override function set_pitch(newSpeed:Float):Float
	{
		if (vorb == null)
			return 1.0;

		audioContext.sourcef(openALSource, audioContext.PITCH, newSpeed);
		updateCompleteTimer();

		return newSpeed;
	}

	override function get_pitch():Float
	{
		return audioContext.getSourcef(openALSource, audioContext.PITCH);
	}

	override function get_paused():Bool
	{
		return audioContext.getSourcei(openALSource, audioContext.PAUSED);
	}

	override function pause()
	{
		if (vorb == null)
			return;

		stopTimers();

		audioContext.sourcePause(openALSource);

		super.pause();
	}

	override function stop()
	{
		if (vorb == null)
			return;

		stopTimers();

		audioContext.sourceStop(openALSource);

		super.stop();

		for (i in 0...3)
		{
			bufferTimeBlocks[i] = 0;
		}
	}

	function snapBuffersToTime(newTime:Float, replay:Bool = false)
	{
		if (openALSource == null || vorb == null)
			return;

		audioContext.sourceStop(openALSource);

		vorb.timeSeek(newTime / 1000);

		if (initializedBuffers)
		{
			audioContext.sourceUnqueueBuffers(openALSource, audioContext.getSourcei(openALSource, audioContext.BUFFERS_QUEUED));
			queueNewBuffers(buffers);
		}
		else
			audioContext.sourceUnqueueBuffers(openALSource, audioContext.getSourcei(openALSource, audioContext.BUFFERS_QUEUED));

		if (replay)
		{
			audioContext.sourcePlay(openALSource);
			resetStreamTimer();
		}
	}

	private function resetStreamTimer()
	{
		if (streamTimer != null)
		{
			streamTimer.stop();
			streamTimer = null;
		}

		streamTimer = new Timer(STREAM_TIMER_CHECK_MS); // Check for buffers each 100ms
		streamTimer.run = bufferStream_task;
	}

	override function set_time(newTime:Float):Float
	{
		if (vorb == null)
			return 0.0;

		if (_stream)
			snapBuffersToTime(newTime, _playing);
		else
			audioContext.sourcef(openALSource, audioContext.SEC_OFFSET, newTime / 1000);

		updateCompleteTimer();

		return newTime;
	}

	private function updateCompleteTimer()
	{
		if (completeTimer != null)
		{
			completeTimer.stop();
			completeTimer = null;
		}

		if (playing)
		{
			var timeRemaining:Float = (_length - time) / pitch;

			if (timeRemaining > 0)
				completeTimer = Timer.delay(onEnd, Std.int(timeRemaining));
			else
			{
				onEnd();
			}
		}
	}

	override function get_time():Float
	{
		if (completed)
			return length;

		//if (_stream)
			return (bufferTimeBlocks[0] * 1000) + (audioContext.getSourcef(openALSource, audioContext.SEC_OFFSET) * 1000);
		/*else
		{
			var value = audioContext.getSourcedvSOFT(openALSource, lime.media.openal.AL.SEC_OFFSET_LATENCY_SOFT, 2);
			var deviceOffset:Float = value[1];
			var realOffset:Float = value[0];
			var time:Float = ((realOffset - deviceOffset) * 1000);

			if (time < 0)
				return 0;
			return Std.int(time);
		}*/
	}

	override function dispose()
	{
		super.dispose();

		stop();

		audioContext.sourceUnqueueBuffers(openALSource, audioContext.getSourcei(openALSource, audioContext.BUFFERS_QUEUED));

		audioContext.deleteSource(openALSource);
		openALSource = null;

		audioContext.deleteBuffer(openALBuffer);
		openALBuffer = null;

		if (buffers != null)
			for (buffer in buffers)
				audioContext.deleteBuffer(buffer);
		if (buffers != null)
			buffers.resize(0);
		if (bufferTimeBlocks != null)
			bufferTimeBlocks.resize(0);

		audioContext = null;
		if (vorb != null)
		{
			vorb.clear();
			vorb = null;
		}

		if (vorbInfo != null)
			vorbInfo = null;
	}

	public function loadFromBuffer(vorbisBufferData:UInt8Array, looped:Bool = false)
	{
		stop();

		if (_stream)
			return;

		completed = false;
		_playing = false;

		_looped = looped;

		audioContext.sourcei(openALSource, audioContext.BUFFER, null);

		if (vorb != null)
		{
			vorb.clear();
			vorb = null;
		}

		if (vorbInfo != null)
		{
			vorbInfo = null;
		}

		vorb = VorbisFile.fromFile(connectedAudio.path);

		vorbInfo = vorb.info();

		_length = vorb.timeTotal() * 1000;

		_audioDataLength = Std.int(Int64.toInt(vorb.pcmTotal()) * vorbInfo.channels * 2);

		var soundData:UInt8Array = vorbisBufferData;

		var vorbChannels = audioContext.FORMAT_STEREO16;
		if (vorbInfo.channels <= 1)
			vorbChannels = audioContext.FORMAT_MONO16;

		audioContext.sourcei(openALSource, audioContext.BUFFER, null);

		audioContext.bufferData(openALBuffer, 0, null, 0, 0);

		audioContext.bufferData(openALBuffer, vorbChannels, soundData, soundData.length, vorbInfo.rate);

		audioContext.sourcei(openALSource, audioContext.BUFFER, openALBuffer);
	}

	public static function readVorbisFileBuffer(vorbisFile:VorbisFile, context:OpenALAudioContext):UInt8Array
	{
		var vorbInfo:VorbisInfo = vorbisFile.info();
		var vorbChannels = context.FORMAT_STEREO16;
		if (vorbInfo.channels <= 1)
			vorbChannels = context.FORMAT_MONO16;
		var vorbRate = vorbInfo.rate;

		var length = Std.int(vorbRate * vorbInfo.channels * 16 * vorbisFile.timeTotal() / 8);
		var buffer = new UInt8Array(length);
		var read = 0, total = 0, readMax;

		while (total < length)
		{
			readMax = 4096;

			if (readMax > length - total)
			{
				readMax = length - total;
			}

			read = vorbisFile.read(buffer.buffer, total, readMax);

			if (read > 0)
			{
				total += read;
			}
			else
			{
				break;
			}
		}

		return buffer.subarray(0, total);
	}

	private function readVorbisBufferStream(vorbisFile:VorbisFile, length:Int):UInt8Array
	{
		var read = 0, total = 0, readMax = 0;

		for (i in 0...2)
		{
			bufferTimeBlocks[i] = bufferTimeBlocks[i + 1];
			vorbisBufferDatas[i] = vorbisBufferDatas[i + 1];
		}

		var buffer = vorbisBufferDatas[2];

		bufferTimeBlocks[2] = vorbisFile.timeTell();

		while (total < length)
		{
			readMax = 4096;

			if (readMax > length - total)
			{
				readMax = length - total;
			}

			read = vorbisFile.read(buffer.buffer, total, readMax);

			if (read > 0)
			{
				total += read;
			}
			else
			{
				break;
			}
		}

		return buffer;
	}

	override function onEnd()
	{
		_playing = false;

		completed = true;

		if (!looped)
			audioContext.sourceStop(openALSource);

		if (looped)
			time = 0;

		if (connectedAudio.onComplete != null)
			connectedAudio.onComplete();

		if (looped)
			play();
	}

	private function stopTimers()
	{
		if (completeTimer != null)
		{
			completeTimer.stop();
			completeTimer = null;
		}

		if (streamTimer != null)
		{
			streamTimer.stop();
			streamTimer = null;
		}
	}
}
