#if !macro
// project specific
import funkin.backend.*;
import funkin.backend.WeekData.WeekFile;
import funkin.backend.Scores.PlayData;
import funkin.objects.menu.Alphabet;
import funkin.objects.FunkinSprite;
import funkin.backend.ScriptHandler;
import funkin.states.*;

//these are functions we use a lot, so make them generally available
import funkin.backend.LanguageHandler._t;
import funkin.backend.LanguageHandler._formatT;

// nevermore specific
import nevermore.backend.Vector3;
import nevermore.core.*;
import funkin.backend.Util; // override

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