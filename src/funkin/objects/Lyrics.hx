package funkin.objects;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;

@:structInit
@:publicFields
class LyricLine {
	var time:Float;
	var text:String = '';
	var subText:String = '';
	var newLine:Bool = false;
	var duration:Float = 0;
}

// fuck haxe and its shitty dynamics
typedef LyricLineData = {
	var time:Float;
	var text:String;
	var subText:String;
	var newLine:Bool;
	var duration:Float;
}

@:structInit
@:publicFields
class LyricData {
	var start:LyricLine = null; // the line with `newLine` as `true`

	var id:Int = 0; // data[2]
	var offset:Float = 0; // data[1]
	var subOffset:Float = 0; // data[4]
	var width:Float = 0; // data[0]
	var subWidth:Float = 0; // data[3]
}

// made by @Raltyro ported by @Rudyrue
class Lyrics extends FlxSpriteGroup {
	public var font:String = 'Rockford-NTLG Medium';
	public var size:Int = 40;

	public var subFont:String = 'Rockford-NTLG Light';
	public var subSize:Int = 24;

	public var speed:Float = 0.0005;

	public var list:Array<LyricLine> = [];

	public function new() {
		super(FlxG.width * 0.5, FlxG.height * 0.75);
	}

	public function load(path:String) {
		if (!FileSystem.exists(path)) return;

		switch haxe.io.Path.extension(path) {
			// haha    ha get it     cuz srtpro27
			case 'srt':
				// uhhhhhhhhhhhhhhhhhhhhhhhhhhhh

			case 'json':
				var data = Json5.parse(File.getContent(path));

				var fuckassList:Array<LyricLineData> = data.list;

				for (event in fuckassList) {
					parseLine({
						time: event.time,
						text: event.text,
						subText: event.subText,
						newLine: event.newLine,
						duration: event.duration
					});
				}
		}
	}

	public var index:Int = 0;
	override function update(_) {
		if (index >= list.length) return;

        final next:LyricLine = list[index];
        if (next.time > Conductor.rawTime - Conductor.offset) return;
		showLine(next);
		index++;
	}

	// this function is some BULLSHITTTTTT
	public var curLineData:LyricData = {};
	public var curLine:FlxTypedSpriteGroup<FlxText>;
	function showLine(line:LyricLine) {
		if (!line.newLine && line.duration <= 0.0) {
			line.duration = Math.POSITIVE_INFINITY; 
		}

		var lineData = _lyricData[index];
		var skip = (Conductor.time - lineData.start.time) * 0.001;
		if (lineData.start.duration - skip <= 0) return;

		if (!line.newLine && (lineData.id != curLineData.id)) return;

		var fuck = getText(lineData.offset, 0, line.text, size, font);
		var subFuck = null;
		if (line.subText != '') {
			var xOff = (line.newLine ? lineData.width - lineData.subWidth : curLineData.width - curLineData.subWidth) * 0.5;

			subFuck = getText(lineData.subOffset + xOff, fuck.height + 8, line.subText, subSize, subFont);
		}

		if (line.newLine) {
			var prevLyric = curLine != null && curLine.exists ? curLine : null;

			var lyric = poolLyrics.pop();
			if (lyric != null) lyric.revive();
			else lyric = new FlxTypedSpriteGroup<FlxText>();
		
			lyric.health = 0;
			lyric.alpha = 1;

			lyric.setPosition(fuck.x - lineData.width * fuck.scale.x * 0.5, fuck.y - fuck.height * 0.5);
			add(lyric);

			curLine = lyric;
			curLineData = _lyricData[index];

			if (prevLyric != null)
				prevLyrics.push(prevLyric);

			var i = prevLyrics.length, lastY = lyric.y;
			while (i > 0) {
				i -= 1; // --/++ is finicky

				prevLyric = prevLyrics[i];
				lastY -= prevLyric.height - 2;
				FlxTween.tween(prevLyric, prevLyric.health == -1 ? {y: lastY} : {y: lastY, alpha: prevLyric.alpha * 0.5},
					Conductor.crotchet * speed, {ease: FlxEase.cubeOut});
			}

			new FlxTimer().start(line.duration - skip, (_) -> {
				lyric.health = -1;
				FlxTween.tween(lyric, {alpha: 0}, Conductor.crotchet * speed, {ease: FlxEase.cubeIn, onComplete: (_) -> {
					FlxTween.cancelTweensOf(lyric);
					for (label in lyric.members) poolLabels[label.size].push(label);
					lyric.kill();
					lyric.clear();
					poolLyrics.push(lyric);
					prevLyrics.remove(lyric);
					remove(lyric);
				}});
			});
		}

		startLabelTween(curLine.add(fuck), curLine, 0, 1);
		if (subFuck != null) startLabelTween(curLine.add(subFuck), curLine, fuck.height + 8, 0.75);
	}

	function startLabelTween(label:FlxText, line:FlxTypedSpriteGroup<FlxText>, yOff:Float, alpha:Float) {
		label.y += 30;
		label.alpha = 0;
		FlxTween.num(0, 1, Conductor.crotchet * speed, {ease: FlxEase.cubeOut}, function(percent) {
			label.y = line.y + yOff + 30 - 20 * percent;
			label.alpha = line.alpha * alpha * percent;
		});
	}

	var poolLabels:Map<Int, Array<FlxText>> = new Map<Int, Array<FlxText>>();
	var prevLyrics:Array<FlxTypedSpriteGroup<FlxText>> = [];
	var poolLyrics:Array<FlxTypedSpriteGroup<FlxText>> = [];
	function getText(x:Float, y:Float, text:String, size:Int, font:String):FlxText {
		var pool = poolLabels[size];
		if (pool == null) poolLabels.set(size, pool = []);

		var fuck = formatText(text);
		text = fuck.text;
		if (fuck.italic) font += ' Italic';
		
		var fontToUse = Paths.font(font + '.ttf');

		var label = pool.pop();
		if (label != null) {
			label.revive();
			label.color = 0xFFFFFFFF;
			label.text = text;
			label.font = fontToUse;
			label.setPosition(x * 0.75, y * 0.75);
		} else {
			label = new FlxText(x * 0.75, y * 0.75, 0, text).setFormat(fontToUse, size, 0xFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
			label.scale.set(0.75, 0.75);
			label.antialiasing = true;
			label.borderSize = 2;
		}
		label.updateHitbox();
		label.visible = true;
		return label;
	}

	function formatText(text:String):{text:String, italic:Bool} {
		var results:{text:String, italic:Bool} = {
			text: text,
			italic: false
		};

		// italics
		// this kinda sucks but whatever
		var firstAsterisk = text.indexOf('*');
		var lastAsterisk = text.lastIndexOf('*');

		if (firstAsterisk != -1 && lastAsterisk != firstAsterisk) {
			results.text = text.substr(firstAsterisk + 1, lastAsterisk - 1);
			results.italic = true;
		}

		return results;
	}

	var _lastData:LyricData = null;
	var _lyricData:Array<LyricData> = [];
	function parseLine(line:LyricLine) {
		var data:LyricData = {};

		var field = getTextField(size, font);
		field.text = formatText(line.text).text;
		data.width = field.textWidth;

		if (line.subText != '') {
			var field = getTextField(subSize, subFont);
			field.text = formatText(line.subText).text;
			data.subWidth = field.textWidth;
		}

		if (line.newLine) {
			_lastData = data;
			data.start = line;
		} else if (_lastData != null) {
			data.id = _lastData.id;
			data.offset = _lastData.width;
			data.subOffset = _lastData.subWidth;
			data.start = _lastData.start;
			_lastData.width += data.width;
			_lastData.subWidth += data.subWidth;
		}

		_lyricData.push(data);
		list.push(line);
	}

	// ignore this
	// does nothing except for getting the width of each text 
	// instead of actually making a new flxtext
	var textFields:Map<Int, TextField> = new Map<Int, TextField>();
	function getTextField(size:Int, font:String):TextField {
		if (textFields.exists(size)) return textFields[size];

		var fontToUse = Paths.font(font + '.ttf');

		var textField = new TextField();
		textField.selectable = false;
		textField.multiline = false;
		textField.wordWrap = false;
		textField.autoSize = LEFT;
		textField.sharpness = 100;
		textField.height = 10;
		@:privateAccess textField.__textFormat.size = size;
		if (FileSystem.exists(fontToUse))
			@:privateAccess textField.__textFormat.font = fontToUse;
		
		textFields.set(size, textField);
		return textField;
	}
}