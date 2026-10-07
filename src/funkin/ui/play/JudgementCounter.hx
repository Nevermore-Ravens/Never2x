package funkin.ui.play;

class JudgementCounter extends FlxSpriteGroup {
	public var names:FlxText;
	public var text:FlxText;

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);

		add(names = new FlxText(x, y, 0, '', 18));
		names.font = Assets.getPath('fonts/LineSeed.ttf');
		names.color = 0xFFFF0000; //sets the default format color to the miss colour
		names.borderStyle = FlxTextBorderStyle.OUTLINE;
		names.borderSize = 1.5;
		regenColors();
		
		add(text = new FlxText((names.x + names.width) + 50, names.y, 75, '', names.size));
		text.font = names.font;
		text.alignment = 'right';
		text.borderStyle = FlxTextBorderStyle.OUTLINE;
		text.borderSize = 1.5;
		text.wordWrap = false;

		updateText();
	}

	function regenColors() {
		names.clearFormats();
		names.text = "";

		var lastNameEnd:Int = 0;
		for (i in 0 ... Judgement.current.length) {
			final judge:Judgement = Judgement.current[i];

			var nameLength:Int = judge.name.length;
			var shortenedName:String = judge.name.charAt(0) + judge.name.charAt(nameLength - 1);

			names.text += shortenedName.toUpperCase() + "\n";
			names.addFormat(new FlxTextFormat(judge.color), lastNameEnd, names.text.length);
			lastNameEnd = names.text.length;
		}
		names.text += "MS";
		names.updateHitbox();
	}

	public function updateText(stats:Statistics) {
		text.text = '';
		for (i in 0 ... stats.judgements.length) {
			var judge:Judgement = stats.judgements[i];
			text.text += Util.moneyString(judge.hits) + '\n';
		}

		text.text += Math.max(stats.misses, 0);
	}
}