#if !macro
// project specific
import nevermore.backend.Vector3;
import nevermore.core.Conductor;
import funkin.backend.*;
import funkin.backend.WeekData.WeekFile;
import funkin.backend.Scores.PlayData;
import funkin.backend.Song.Chart;
import funkin.objects.menu.Alphabet;
import funkin.objects.FunkinSprite;
import funkin.backend.ScriptHandler;
import funkin.states.*;
import funkin.backend.FlxAudioHandler;
import funkin.backend.audio.FlxAudio;

//these are functions we use a lot, so make them generally available
import funkin.backend.LanguageHandler._t;
import funkin.backend.LanguageHandler._formatT;

// flixel specific
import flixel.*;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxColor as FlxColour;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;

// haxe
import sys.FileSystem;
import sys.io.File;
import hxjson5.Json5;
import haxe.Json;

using StringTools;
#end