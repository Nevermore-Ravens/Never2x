package funkin.backend.audio;

class FlxAudioGroup {
	public var members:Array<FlxAudio> = [];

	public var limit:Int = 0;

	public var volume(default, set):Float;
	public var pitch(default, set):Float;
	public var time(default, set):Float;

	public function new(?_limit:Int = 0) {
		if (_limit > 0) limit = _limit;
	}

	public function add(sound:FlxAudio):FlxAudio {
		if (members.contains(sound) || members.length >= limit) return sound;
		members.push(sound);

		return sound;
	}

	public function remove(sound:FlxAudio):FlxAudio {
		if (!members.contains(sound) || sound == null) return sound;
		members.remove(sound);
		
		return sound;
	}

	public function destroy():Void {
		while (members.length > 0) {
			var sound:FlxAudio = members[0];
			if (sound == null) {
				members.remove(sound);
				continue;
			}

			remove(sound);
			sound.destroy();
			sound = null;
		}
	}

	public function play():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.play();
		}
	}

	public function stop():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.stop();
		}
	}

	public function pause():Void {
		for (sound in members) {
			if (sound == null) continue;
			sound.pause();
		}
	}

	function set_volume(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.volume = value;
		}
		
		return volume = value;
	}

	function set_pitch(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.pitch = value;
		}
		
		return pitch = value;
	}

	function set_time(value:Float):Float {
		for (sound in members) {
			if (sound == null) continue;
			sound.time = value;
		}
		
		return time = value;
	}
}