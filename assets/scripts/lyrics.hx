import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import flixel.group.FlxTypedSpriteGroup;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxCamera;

import haxe.ds.IntMap;
import funkin.backend.Conductor;
import sys.FileSystem;

var forceRegenerate = true;
var font = 'Rockford-NTLG Medium', size = 40;
var subFont = 'Rockford-NTLG Light', subSize = 24, subSize2 = 16;
var hiragana:Array<String> = [
//  a   	i   	u   	e   	o
	"あ",	"い",	"う",	"え",	"お",
	"か",	"き",	"く",	"け",	"こ", // k
	"さ",	"し",	"す",	"せ",	"そ", // s
	"た",	"ち",	"つ",	"て",	"と", // t
	"な",	"に",	"ぬ",	"ね",	"の", // n
	"は",	"ひ",	"ふ",	"へ",	"ほ", // h
	"ま",	"み",	"む",	"め",	"も", // m
	"や",			"ゆ",			"よ", // y
	"ら",	"り",	"る",	"れ",	"ろ", // r
	"わ",	"を", // w
	"ん" // n
];

var camera:FlxCamera;
var debugLabel:FlxText;

var obj:FlxGroup;
var curLyric:FlxTypedSpriteGroup;
var curLyricData:Array<Dynamic>;
var prevLyrics:Array<FlxTypedSpriteGroup> = [];
var poolLyrics:Array<FlxTypedSpriteGroup> = [];

// weird stuff going on with sizes
var poolLabels:IntMap<Array<FlxText>> = new IntMap();
var textFields:IntMap<TextField> = new IntMap();

function create() {
	game.add(obj = new FlxTypedSpriteGroup(FlxG.width * 0.5, FlxG.height * 0.75));
	obj.cameras = [game.camHUD];
}

function startLabelTween(label:FlxText, alpha:Float) {
	label.y += 30;
	label.alpha = 0;
	FlxTween.tween(label, {alpha: alpha, y: label.y - 20}, Conductor.crotchet * 0.0005, {ease: FlxEase.cubeOut});
}

function getLabel(size:Int, font:String, text:String, x:Float, y:Float):FlxText {
	var pool = poolLabels.get(size);
	if (pool == null) poolLabels.set(size, pool = []);

	var oldText = text;
	text = getText(text);
	if (oldText != text) font += ' Italic';

	var fontToUse = Paths.font(font + '.ttf');

	var label = pool.pop();
	if (label != null) {
		label.revive();
		label.text = text;
		label.font = fontToUse;
		label.setPosition(x * 0.75, y * 0.75);
	}
	else {
		label = new FlxText(x * 0.75, y * 0.75, 0, text).setFormat(fontToUse, size, 0xFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
		label.scale.set(0.75, 0.75);
		label.antialiasing = true;
		label.borderSize = 2;
	}
	label.updateHitbox();
	return label;
}

// 0 => width, 1 => offset, 2 => id, | 3 => width, 4 => offset | <- (for subtexts), 5 => furiganas
// furiganas - offset, hiragana in index to hiragana tables
var defaultData:Array<Dynamic> = [0, 0, 0, 0, 0/*, []*/];
var eventGenerateKey = "LYRIC_GENERATED_EVENT";
function eventTriggered(name, args) {
	if (name != "Lyric") return;

	var duration = args[3], skip = (Conductor.time - game.eventHandler.list[game.eventHandler.index].time) * 0.001;
	if (duration - skip <= 0) return;

	var data = args[args.length - 2] == eventGenerateKey ? args[args.length - 1] : defaultData;
	if (args[2] && (curLyric == null || !curLyric.exists || data[2] != curLyricData[2])) return;

	var label = getLabel(size, font, args[0], data[1], 0);
	var subLabel = null;
	if (args[1] != "") {
		var xOff = (args[2] ? curLyricData[0] - curLyricData[3] : data[0] - data[3]) * 0.5;
		subLabel = getLabel(subSize, subFont, args[1], data[4] + xOff, label.height + 8);
	}

	if (!args[2]) {
		var prevLyric = curLyric != null && curLyric.exists ? curLyric : null;

		var lyric = poolLyrics.pop();
		if (lyric != null) lyric.revive();
		else {
			lyric = new FlxTypedSpriteGroup();
			//lyric.directAlpha = true;
		}
		lyric.health = 0;
		lyric.alpha = 1;

		lyric.setPosition(label.x - data[0] * label.scale.x * 0.5, label.y - label.height * 0.5);
		obj.add(lyric);

		curLyric = lyric;
		curLyricData = data;

		if (prevLyric != null)
			prevLyrics.push(prevLyric);

		var i = prevLyrics.length, lastY = lyric.y;
		while (i > 0) {
			i -= 1; // --/++ is finicky

			prevLyric = prevLyrics[i];
			lastY -= prevLyric.height - 2;
			FlxTween.tween(prevLyric, prevLyric.health == -1 ? {y: lastY} : {y: lastY, alpha: prevLyric.alpha * 0.5},
				Conductor.crotchet * 0.0005, {ease: FlxEase.cubeOut});
		}

		new FlxTimer().start(duration - skip, (_) -> {
			lyric.health = -1;
			FlxTween.tween(lyric, {alpha: 0}, Conductor.crotchet * 0.0005, {ease: FlxEase.cubeIn, onComplete: (_) -> {
				FlxTween.cancelTweensOf(lyric);
				for (label in lyric.members) poolLabels.get(label.size).push(label);
				lyric.kill();
				lyric.clear();
				poolLyrics.push(lyric);
				prevLyrics.remove(lyric);
				obj.remove(lyric);
			}});
		});
	}

	startLabelTween(curLyric.add(label), 1);
	if (subLabel != null) startLabelTween(curLyric.add(subLabel), 0.75);
}

function getText(text:String) {
	var firstAsterisk = text.indexOf('*');
	var lastAsterisk = text.lastIndexOf('*');

	if (firstAsterisk != -1 && lastAsterisk != firstAsterisk) {
		text = text.substr(1, text.length - 2);
	}

	return text;
}

function getTextField(size:Int, font:String):TextField {
	if (textFields.exists(size)) return textFields.get(size);

	var fontToUse = Paths.font(font + '.ttf');

	var textField = new TextField();
	textField.selectable = false;
	textField.multiline = false;
	textField.wordWrap = false;
	textField.autoSize = true;
	textField.sharpness = 100;
	textField.height = 10;
	textField.embedFonts = true;
	textField.__textFormat.size = size;
	if (FileSystem.exists(fontToUse))
		textField.__textFormat.font = fontToUse;
	return textField;
}

var lastEvent, lastFont;
function eventPushedUnique(event) {
	if (event.name != "Lyric") return;

	var args = event.args;
	if (args.length == 2) {
		// alt/old format
		args.insert(1, "");
		args.insert(2, false);
		args[3] = Std.parseFloat(Std.string(args[3])); // sometimes its a string, sometimes its not
	}

	if (args[args.length - 2] == eventGenerateKey) {
		if (forceRegenerate) for (i in 0...2) args.remove(args[args.length - 1]);
		else return;
	}

	// theres something with params being duplicated, which i assume for performance but it breaks shit here.
	args = event.args = event.args.copy();

	var data = defaultData.copy();
	args.push(eventGenerateKey);
	args.push(data);

	var field = getTextField(size, font);
	field.text = getText(args[0]);
	data[0] = field.textWidth;

	if (args[1] != "") {
		var field = getTextField(subSize, subFont);
		field.text = getText(args[1]);
		data[3] = field.textWidth;
	}

	if (!args[2]) {
		data[2] = defaultData[2]++;
		lastEvent = event;
	}
	else if (lastEvent != null) {
		var otherArgs = lastEvent.args;
		var otherData = otherArgs[otherArgs.length - 1];

		data[2] = otherData[2]; // ID
		data[1] = otherData[0]; // Offset from the parent last width
		data[4] = otherData[3]; // ^ but for subtexts
		otherData[0] += data[0]; // Adds parent width with this width
		otherData[3] += data[3]; // ^ but for subtexts
	}
}