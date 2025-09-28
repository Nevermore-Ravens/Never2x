package funkin.states;

import funkin.objects.ui.Border;
import flixel.math.FlxRect;
import flixel.math.FlxAngle;
import flixel.graphics.FlxGraphic;
import flixel.addons.effects.FlxSkewedSprite;
import funkin.objects.FunkinSprite;
import funkin.objects.ui.SwirlBG;
import funkin.shaders.TileLine;
import funkin.shaders.GraphGradient;
import funkin.backend.WeekData;

using StringTools;

class StoryMenuState extends FunkinState {
	public static var fromPlayState:Bool = false;
	static var curHover:Int = 0;
	var curDiffSelected:Int = 0;
	var curSelected:Int = -1;
	var draggedOnce:Bool = false;
	var dragging:Bool = false;
	var dragY:Float = -1;
	var diffPoints:Array<Float>;
	var curScore:Int = 0;
	var lerpScore:Float = 0;
	var weekList:Array<WeekFile>;
	
	var banners:FlxTypedGroup<FunkinSprite>;
	var infoGroup:FlxSpriteGroup;
	var selectOutline:FunkinSprite;
	var selectBG:FunkinSprite;
	var selectNum:FlxText;
	var selectTitle:FlxText;
	var selectSubtitle:FlxText;
	var selectTri:FunkinSprite;

	var graphTwn:FlxTween;
	var graphShader:GraphGradient;
	var scoreBG:FunkinSprite;
	var graph:FunkinSprite;
	var graphLines:FlxSpriteGroup;
	var graphDots:FlxSpriteGroup;
	var bestTitle:FlxText;
	var bestScore:FlxText;
	var rankTitle:FlxText;
	var bestRank:FlxText;
	var songBGs:FlxTypedSpriteGroup<FunkinSprite>;
	var songNames:FlxTypedSpriteGroup<FlxText>;
	var songDiffs:FlxTypedSpriteGroup<FlxText>;
	var diffBGs:FlxTypedGroup<FunkinSprite>;
	var diffNames:FlxTypedGroup<FlxText>;
	var diffSel:FunkinSprite;
	var diffColors:Array<Array<Float>> = [
		[255 / 255, 226 / 255, 40 / 255, 1.0],
		[255 / 255, 40 / 255, 108 / 255, 1.0],
		[195 / 255, 40 / 255, 255 / 255, 1.0]
	];

	var borderTop:Border;
	var borderBot:Border;

	var bg:SwirlBG;
	var lineShader:TileLine;

	var inTween:Bool = false;

	override function create():Void {
		super.create();

		// temporary colors (or colours cuz yunno, rudy rudy)
		add(bg = new SwirlBG(0xFF3D3473, 0xFFF344D3));

		if (!Settings.data.reducedQuality) {
			var lineBG = new FunkinSprite();
			lineBG.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
			lineShader = new TileLine();
			lineShader.color1.value = [0, 0, 0, 0.375];
			lineShader.color2.value = [0, 0, 0, 0.5];
			lineShader.density.value = [200.0];
			lineShader.time.value = [SwirlBG.time / 64];
			lineBG.shader = lineShader;
			add(lineBG);
		}

		add(selectOutline = new FunkinSprite(FlxG.width * 0.5, FlxG.height * 0.5, Paths.image("menus/Story/outline")));
		selectOutline.offset.set(selectOutline.frameWidth * 0.5, selectOutline.frameHeight * 0.5);
		selectOutline.alpha = 0.0;

		WeekData.reload();
		weekList = [for (week in WeekData.list) if (!week.hideStory) week];
		curHover = Std.int(FlxMath.bound(curHover, 0, weekList.length - 1));
		loadWeeks();

		add(infoGroup = new FlxSpriteGroup());
		infoGroup.setPosition(FlxG.width * 0.5 - 345, FlxG.height * 0.5);
		
		infoGroup.add(selectBG = new FunkinSprite());
		selectBG.makeGraphic(635, 120, 0x80000000);
		
		infoGroup.add(selectNum = new FlxText(50, 15, selectBG.width - 40, 'Week ${weekList[curHover].weekNum}:'));
		selectNum.setFormat(Paths.font("menus/GOTHIC.TTF"), 18, 0xFFFFFFFF, LEFT);
		
		infoGroup.add(selectTitle = new FlxText(50, 35, selectNum.fieldWidth, weekList[curHover].name));
		selectTitle.setFormat(Paths.font("menus/GOTHICB.TTF"), 32, 0xFFFFFFFF, LEFT);
		
		infoGroup.add(selectSubtitle = new FlxText(50, 75, selectTitle.fieldWidth, weekList[curHover].subtitle));
		selectSubtitle.setFormat(Paths.font("menus/GOTHIC.TTF"), 18, 0xFFFFFFFF, LEFT);
		
		infoGroup.add(selectTri = new FunkinSprite(15, 40, Paths.image("menus/triangle")));
		selectTri.flipX = true;
		selectTri.origin.x += 3; // UUUUUGGGGGGGGHHHHHHHHH
		
		infoGroup.add(scoreBG = new FunkinSprite(0, 125).makeGraphic(1, 1, 0x80000000));
		scoreBG.origin.set();
		scoreBG.scale.set(375, 0);

		infoGroup.add(graph = new FunkinSprite(170, 200).makeGraphic(175, 155, 0x00000000));
		if (Settings.data.shaders)
			graphShader = new GraphGradient();

		graph.shader = (Settings.data.shaders) ? graphShader : null;
		graph.alpha = 0;

		infoGroup.add(graphDots = new FlxSpriteGroup());
		graphDots.setPosition(graph.x, graph.y);
		graphDots.directAlpha = true;

		infoGroup.add(graphLines = new FlxSpriteGroup());
		graphLines.setPosition(graph.x, graph.y);
		graphLines.directAlpha = true;

		infoGroup.add(bestRank = new FlxText(-55, 95, 0, "S+")); // longest text
		bestRank.setFormat(Paths.font("menus/GOTHICBI.TTF"), 256, 0xFFFFFFFF, LEFT);
		bestRank.updateHitbox();
		bestRank.clipRect = FlxRect.get(55, 0, bestRank.frameWidth - 55, bestRank.frameHeight);
		bestRank.alpha = 0;
		bestRank.text = "";

		infoGroup.add(rankTitle = new FlxText(15, 315, 0, 'BEST GRADE:'));
		rankTitle.setFormat(Paths.font("menus/GOTHIC.TTF"), 14, 0xFFFFFFFF, LEFT);
		rankTitle.alpha = 0;

		infoGroup.add(bestTitle = new FlxText(15, 140, 0, 'BEST SCORE:'));
		bestTitle.setFormat(Paths.font("menus/GOTHIC.TTF"), 14, 0xFFFFFFFF, LEFT);
		bestTitle.alpha = 0;

		infoGroup.add(bestScore = new FlxText(15 + bestTitle.width, 125, 0, '0'));
		bestScore.setFormat(Paths.font("menus/GOTHICI.TTF"), 52, 0xFFC8B4D6, LEFT);
		bestScore.alpha = 0;

		infoGroup.add(songBGs = new FlxTypedSpriteGroup<FunkinSprite>());
		infoGroup.add(songNames = new FlxTypedSpriteGroup<FlxText>());
		infoGroup.add(songDiffs = new FlxTypedSpriteGroup<FlxText>());

		add(diffBGs = new FlxTypedGroup<FunkinSprite>());
		add(diffNames = new FlxTypedGroup<FlxText>());
		add(diffSel = new FunkinSprite(-999, -999, Paths.image("menus/Story/diffGrad")));
		diffSel.colorTransform.alphaOffset = -117; // the first man to use alphaOffset

		var storyTile = new flixel.addons.display.FlxBackdrop(Paths.image('menus/Story/bigText'), Y);
		storyTile.velocity.y = 25;
		add(storyTile);
		
		add(borderTop = new Border(true, "SELECT A WEEK • ", "Story"));
		add(borderBot = new Border(false));

		// TODO: make a shortcut for these buttons for cleanup.
		final buttonY = borderBot.border.y + 58; // unfortunately 58 is the only number that centers it.
		var upButton = new FunkinSprite(borderBot.x + 40, buttonY, Paths.image('menus/keyIndicator'));
		upButton.scrollFactor.set(0, 1);
		borderBot.add(upButton);

		var downButton = new FunkinSprite(upButton.x + upButton.width + 3, buttonY, Paths.image('menus/keyIndicator'));
		downButton.angle = 180;
		downButton.scrollFactor.set(0, 1);
		borderBot.add(downButton);

		var changeSongTxt = new FlxText((downButton.x + downButton.width) + 5, downButton.y + 8, 0, 'SELECT WEEK', 16);
		changeSongTxt.font = Paths.font('menus/ITC Avant Garde Gothic CE Book.otf');
		changeSongTxt.scrollFactor.set(0, 1);
		borderBot.add(changeSongTxt);
		
		var leftButton = new FunkinSprite(changeSongTxt.x + changeSongTxt.width + 50, buttonY, Paths.image('menus/keyIndicator'));
		leftButton.angle = 270;
		leftButton.scrollFactor.set(0, 1);
		borderBot.add(leftButton);

		var rightButton = new FunkinSprite(leftButton.x + leftButton.width + 3, buttonY, Paths.image('menus/keyIndicator'));
		rightButton.angle = 90;
		rightButton.scrollFactor.set(0, 1);
		borderBot.add(rightButton);

		var changeDiffTxt = new FlxText((rightButton.x + rightButton.width) + 5, rightButton.y + 8, 0, 'SELECT DIFFICULTY', 16);
		changeDiffTxt.font = Paths.font('menus/ITC Avant Garde Gothic CE Book.otf');
		changeDiffTxt.scrollFactor.set(0, 1);
		borderBot.add(changeDiffTxt);

		if (fromPlayState) {
			fromPlayState = false;

			borderTop.y += FlxG.height;
			borderBot.y -= FlxG.height;

			var ogOffsets = [];
			var ogBorderOffsetY = borderTop.border.offset.y;
			for (thing in borderBot.members) {
				ogOffsets.push(thing.offset.y);
				thing.visible = thing == borderBot.border;
			}
			FlxTween.num(0, 1, 0.75, {ease: FlxEase.cubeOut}, function(num) {
				final height = FlxG.height * (1 - num);
				borderTop.y = height;
				borderBot.y = -height;
				borderBot.border.clipGraphic(0, 0, borderBot.border.graphic.width, borderBot.border.graphic.height + height);
				borderTop.border.clipGraphic(0, -height, borderTop.border.graphic.width, borderTop.border.graphic.height + height);
				borderTop.border.offset.y = ogBorderOffsetY + height;

				for (i => thing in borderBot.members) {
					if (thing == borderBot.border || borderTop.border.frameHeight - 40 >= thing.y + thing.height - 5) continue;

					thing.visible = true;
					final y = Math.max((borderTop.border.frameHeight - 40) - thing.y, 0);
					thing.clipGraphic(0, y, thing.graphic.width, thing.graphic.height - y);
					thing.offset.y = ogOffsets[i] - y;
				}
			});
		} else
			Border.transitionTween(true, true, borderTop);
	}

	override function update(delta:Float):Void {
		super.update(delta);
		
		if (!Settings.data.reducedQuality) {
			selectTri.angle += delta * 160;
			lineShader.time.value[0] = SwirlBG.time / 64;

			lerpScore = FlxMath.lerp(lerpScore, curScore, delta * 12.5);
			bestScore.text = Std.string(Math.round(lerpScore));
		}
		bg.speed = FlxMath.lerp(bg.speed, 1.0, delta * 15.0);
		
		for (i => bg in diffBGs.members) {
			bg.colorTransform.redMultiplier = FlxMath.lerp(bg.colorTransform.redMultiplier, (i == curDiffSelected) ? diffColors[i][0] : 0.1, delta * 15);
			bg.colorTransform.greenMultiplier = FlxMath.lerp(bg.colorTransform.greenMultiplier, (i == curDiffSelected) ? diffColors[i][1] : 0.1, delta * 15);
			bg.colorTransform.blueMultiplier = FlxMath.lerp(bg.colorTransform.blueMultiplier, (i == curDiffSelected) ? diffColors[i][2] : 0.1, delta * 15);
		}
		if (curSelected > -1)
			diffSel.colorTransform.alphaOffset = FlxMath.lerp(diffSel.colorTransform.alphaOffset, -35, delta * 15 * diffBGs.members[curDiffSelected].alpha);
		else
			diffSel.colorTransform.alphaOffset = FlxMath.lerp(diffSel.colorTransform.alphaOffset, -117, delta * 15);

		selectOutline.alpha = FlxMath.lerp(selectOutline.alpha, -Math.min(curSelected, 0), delta * 10);
		selectOutline.scale.x = selectOutline.scale.y = 1.15 - 0.15 * selectOutline.alpha;

		if (curHover < 0) return;

		for (i => banner in banners.members) {
			banner.setPosition(
				FlxMath.lerp(banner.x, FlxG.width * 0.5 + 55 * (i - curHover), delta * 15),
				FlxMath.lerp(banner.y, FlxG.height * 0.5 + 225 * (i - curHover), delta * 15)
			);

			banner.alpha = FlxMath.lerp(banner.alpha, (curSelected == -1 || i == curSelected) ? 0.9 : 0.0, delta * 10);
		}

		final curBanner = banners.members[curHover];
		selectOutline.setPosition(curBanner.x, curBanner.y);
		infoGroup.setPosition(
			FlxMath.lerp(infoGroup.x, (curSelected == -1) ? curBanner.x - 345 : 80, delta * 15),
			FlxMath.lerp(infoGroup.y, (curSelected == -1) ? curBanner.y : 155, delta * 15)
		);

		if (!inTween)
			(curSelected == -1 ? scrollInputs : weekInputs)();
	}

	function selectWeek() {
		FlxG.sound.play(Paths.audio("popup_select", 'sfx'));
		curDiffSelected = Difficulty.list.indexOf(Difficulty.current);
		curSelected = curHover;
		inTween = true;
		final week = weekList[curSelected];

		for (i => diff in Difficulty.list) {
			// 942 will be the only number to keep consistent spacing so TIME TO BREAK TABLES
			var sqr = new FunkinSprite(borderBot.border.x + 942, borderBot.border.y, Paths.image("menus/Story/diffSqr"));
			sqr.x -= sqr.width * 0.75 * (Difficulty.list.length - 1 - i);
			sqr.setColorTransform(0.1, 0.1, 0.1, 0, 0, 0, 0, 0);
			diffBGs.add(sqr);

			var txt = new FlxText(sqr.x, sqr.y + sqr.height * 0.5, sqr.width, diff.toUpperCase());
			if (i == curDiffSelected)
				txt.setFormat(Paths.font("menus/GOTHICB.TTF"), 16, 0xFFFFFFFF, CENTER);
			else
				txt.setFormat(Paths.font("menus/GOTHIC.TTF"), 16, FlxColor.fromRGBFloat(diffColors[i][0], diffColors[i][1], diffColors[i][2], 1.0), CENTER);
			txt.y -= txt.height * 0.5;
			txt.alpha = 0.0;
			diffNames.add(txt);
		}
		diffSel.setPosition(diffBGs.members[curDiffSelected].x, diffBGs.members[curDiffSelected].y + diffBGs.members[curDiffSelected].height - diffSel.height);

		final curDiff = (Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.list[curDiffSelected];
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		final songs = weekList[curSelected].songs;
		final splitWidth = (songs.length < 2) ? graph.width : graph.width / (songs.length - 1);
		final songHeight = (250 - 5 * (songs.length - 1)) / songs.length;
		curScore = 0;
		var allSongs = true;
		var acc = 1.0;
		diffPoints = [];
		for (i => song in songs) {
			final meta = Meta.load(song.id);
			final diffs = meta.rating.get(curDiff);

			// TODO: use the actual number when we got more ratings in the meta
			diffPoints.push((diffs == null || diffs.length < (diffIdx + 1)) ? 0 : Math.floor(diffs[diffIdx]) * 0.05);

			final score = Scores.get(song.id, Difficulty.list[curDiffSelected], meta.hasModchart);
			curScore += score.score;
			acc *= score.accuracy * 0.01;
			allSongs = allSongs && (score.accuracy >= 0);

			final div = (songs.length < 2) ? 1 : i / (songs.length - 1);
			var dot = new FunkinSprite(FlxMath.lerp(0, graph.width, div), graph.height, Paths.image("menus/Story/graphDot"));
			dot.clipGraphic(0, 0, dot.frameWidth, 4.5);
			dot.updateHitbox();
			dot.x -= dot.width * 0.5;
			dot.y -= dot.height * 0.5;
			graphDots.add(dot);

			var bg = new FunkinSprite((scoreBG.x - infoGroup.x) + scoreBG.scale.x + 5, (scoreBG.y - infoGroup.y) + (5 + songHeight) * i).makeGraphic(1, 1, 0x80000000);
			bg.scale.set(selectBG.width - bg.x, songHeight);
			bg.updateHitbox();
			bg.origin.set();
			bg.offset.set();
			bg.alpha = 0;
			
			final nameTxt = (FlxG.random.bool(meta.rngChance) ? meta.randomName : meta.songName);
			var name:FlxText = new FlxText(bg.x + 5, bg.y + bg.height * 0.5, bg.width - 5, nameTxt.toUpperCase());
			name.setFormat(Paths.font("menus/GOTHIC.TTF"), 14, 0xFFFFFFFF, LEFT);
			name.y -= name.height * 0.5;
			name.alpha = 0;

			final diffTxt = (diffs == null || diffs.length < (diffIdx + 1)) ? "?" : Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : "");
			var diff:FlxText = new FlxText(bg.x + bg.width - 5, bg.y + bg.height, 0, diffTxt);
			diff.setFormat(Paths.font("menus/GOTHICB.TTF"), 50, 0xFFA0A0A0, RIGHT);
			diff.updateHitbox();
			diff.clipGraphic(0, 0, diff.frameWidth, diff.frameHeight * 0.75);
			diff.x -= diff.frameWidth;
			diff.y -= diff.frameHeight;
			diff.alpha = 0;
			
			songBGs.add(bg);
			songNames.add(name);
			songDiffs.add(diff);
			
			if (songs.length > 1 && i == songs.length - 1) continue;

			var line = new FunkinSprite(splitWidth * i, graph.height).makeGraphic(1, 1, 0xFFFFFFFF);
			line.scale.set(splitWidth, 2);
			line.updateHitbox();
			line.y -= line.height * 0.5;
			graphLines.add(line);
		}

		if (Settings.data.reducedQuality)
			bestScore.text = Std.string(curScore);
		final rank:Ranking = allSongs ? Ranking.getFromAccuracy(acc * 100) : {};
		bestRank.text = rank.name;
		bestRank.color = rank.color;

		if (Settings.data.shaders){
			graphShader.setPoints(diffPoints);
			graphShader.progress.value[0] = 0;
		}

		graphDots.alpha = 0.0;
		graphLines.alpha = 0.0;
		final halfDiv = 0.5 / songs.length;
		final diffDiv = 0.5 / Difficulty.list.length;
		FlxTween.num(0, 0.5, 0.375, null, function(num) {
			for (i => bg in songBGs.members) {
				final name = songNames.members[i];
				final diff = songDiffs.members[i];

				if (num < halfDiv * i || bg.alpha >= 1.0) continue;

				bg.alpha = name.alpha = diff.alpha = FlxEase.cubeIn((num - halfDiv * i) / halfDiv);
				bg.offset.x = name.offset.x = diff.offset.x = -30 * (1.0 - bg.alpha);
			}
			for (j in 0...diffBGs.members.length) {
				final i = Difficulty.list.length - 1 - j;
				final bg = diffBGs.members[i];
				final name = diffNames.members[i];

				if (num < diffDiv * i || bg.alpha >= 1.0) continue;

				bg.alpha = name.alpha = FlxEase.quadOut(Math.min((num - diffDiv * i) / diffDiv, 1.0));
				bg.offset.y = name.offset.y = 15 * (1.0 - bg.alpha);
			}
		});

		final curBanner = banners.members[curHover];
		final imgScale = curBanner.graphic.width / 640;
		final startScale = 640 / curBanner.graphic.width;
		final scale = FlxG.height / Math.min(360 * imgScale, curBanner.graphic.height - week.selectedClipY);
		
		FlxTween.num(0, 1, 0.75, {ease: FlxEase.quintInOut, onComplete: function(twn) {
			inTween = false;
		}}, function(num) {
			curBanner.scale.x = curBanner.scale.y = FlxMath.lerp(startScale, scale, num);
			final clipY = FlxMath.lerp(week.unselectedClipY, week.selectedClipY, num);
			curBanner.clipGraphic(0, clipY, curBanner.graphic.width, Math.min(FlxMath.lerp(190, 360, num) * imgScale, curBanner.graphic.height - clipY));
			curBanner.origin.set(curBanner.frameWidth * 0.5, curBanner.frameHeight * 0.5);
			curBanner.offset.copyFrom(curBanner.origin);

			graphDots.alpha = num;
			for (i => dot in graphDots.members) {
				final height = graph.frameHeight * diffPoints[i] * num + 4.5;
				dot.clipGraphic(0, 0, dot.frameWidth, height + 1);
				dot.y = graph.y + graph.height - height;
			}
			graphLines.alpha = num;
			for (i => line in graphLines.members) {
				if (graphLines.length == 1) {
					line.y = graph.y + graph.height * (1.0 - diffPoints[i] * num) - line.height * 0.5;
					continue;
				}

				final height1 = graph.height * diffPoints[i] * num;
				final height2 = graph.height * diffPoints[i + 1] * num;
				line.y = graph.y + graph.height - FlxMath.lerp(height1, height2, 0.5) - line.height * 0.5;
				line.angle = Math.atan((height1 - height2) / splitWidth) * FlxAngle.TO_DEG;
				line.scale.x = Math.sqrt(splitWidth * splitWidth + Math.pow(height2 - height1, 2));
			}
			if (Settings.data.shaders)
				graphShader.progress.value[0] = num;
		});

		FlxTween.tween(graph, {alpha: 1.0}, 0.25, {ease: FlxEase.cubeOut});
		var scoreTwn = FlxTween.tween(scoreBG.scale, {y: 250}, 0.25, {ease: FlxEase.cubeOut});
		scoreTwn.then(FlxTween.num(0, 1, 0.25, {ease: FlxEase.cubeOut}, function(num) {
			for (obj in [bestRank, rankTitle, bestTitle, bestScore]) {
				obj.alpha = num;
				obj.offset.y = 30 * (1 - num);
			}
		}));
	}
	
	function retarget(?dir:Int = 0) {
		banners.members[curHover].color = 0xFF808080;
		curHover = FlxMath.wrap(curHover + dir, 0, weekList.length - 1);
		banners.members[curHover].color = 0xFFFFFFFF;

		bg.speed = 10;
		selectNum.text = 'Week ${weekList[curHover].weekNum}:';
		selectTitle.text = weekList[curHover].name;
		selectSubtitle.text = weekList[curHover].subtitle;
		
		selectOutline.alpha = 0.0;
	}

	function scrollInputs() {
		final downJustPressed:Bool = Controls.justPressed('ui_down');

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			final cacheHover = curHover;
			curHover = -1;
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			Border.transitionTween(true, false, borderTop, 0, 0.25, function() {
				curHover = cacheHover;
				FlxG.switchState(new funkin.states.MainMenuState());
			});
		} else if (FlxG.mouse.wheel != 0 || downJustPressed || Controls.justPressed('ui_up')) {
			retarget(FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : (downJustPressed ? 1 : -1));
			FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
		} else if (Controls.justPressed('accept'))
			selectWeek();

		for (i => banner in banners.members) {
			if (FlxG.mouse.justReleased && !draggedOnce && FlxG.mouse.x >= banner.x - banner.width * 0.5 && FlxG.mouse.x <= banner.x + banner.width * 0.5 && FlxG.mouse.y >= banner.y - banner.height * 0.5 && FlxG.mouse.y <= banner.y + banner.height * 0.5) {
				if (i != curHover) {
					retarget(i - curHover);
					FlxG.sound.play(Paths.audio("menu_move", 'sfx'));
				} else
					selectWeek();
			}
		}

		if (FlxG.mouse.justPressed) {
			dragging = true;
			dragY = FlxG.mouse.screenY;
		} else if (dragging) {
			final dist = Math.round((FlxG.mouse.screenY - dragY) / 150);

			if (dist != 0) {
				draggedOnce = true;
				dragY += 150 * dist;
				retarget(-dist);
				FlxG.sound.play(Paths.audio("menu_move", "sfx"));
			}

			if (FlxG.mouse.justReleased) {
				dragging = false;
				draggedOnce = false;
				dragY = -1;
			}
		}
	}

	function confirmWeek() {
		Addons.current = weekList[curSelected].folder;
		
		Dialogue.fromMenu = true;
		PlayState.songList = [for (song in weekList[curSelected].songs) song.id];
		WeekData.current = curSelected;
		Difficulty.current = Difficulty.list[curDiffSelected];
		PlayState.storyMode = true;
		PauseMenu.musicPath = weekList[curSelected].pauseMusic;

		FlxG.mouse.visible = false;
		FlxG.sound.play(Paths.audio("menu_finish", "sfx"));
		FlxTween.num(1, 0, 1, {ease: FlxEase.quadOut}, function(num) {
			Conductor.inst.volume = num;
		});

		var rouxls = new FunkinSprite(FlxG.width * 0.5 - 1, 0);
		rouxls.makeGraphic(1, 1, 0xFFFFFFFF);
		rouxls.scale.set(2, FlxG.height);
		rouxls.updateHitbox();
		insert(members.indexOf(borderTop), rouxls);

		FlxTween.tween(rouxls.scale, {x: FlxG.width}, 0.25, {ease: FlxEase.quartOut});
		FlxTween.color(rouxls, 1, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.cubeOut});

		final cacheHover = curHover;
		curHover = -1;
		var ogOffsets = [for (thing in borderBot.members) thing.offset.y];
		var ogBorderOffsetY = borderTop.border.offset.y;
		FlxTween.num(1, 0, 1, {ease: FlxEase.cubeIn, startDelay: 0.25, onComplete: function(twn) {
			curHover = cacheHover;

			new FlxTimer().start(1, function(tmr) {
				for (mem in members) {
					if (mem == null || !mem.exists || !mem.alive) continue;
					mem.visible = mem == borderTop || mem == borderBot;
				}

				Paths.clearExcept([
					Paths.getCacheKey('menus/border.png', 'IMG', 'images'),
					Paths.getCacheKey('menus/borderTop.png', 'IMG', 'images')
				]);

				FlxG.switchState(new PlayState());
			});
			// PlayState.inTransition = true;
			// openSubState(new FreeplayTransition(curSong.meta, function() {
			// 	FlxG.switchState(new PlayState());
			// 	return false;
			// }, true));
		}}, function(num) {
			final height = FlxG.height * (1 - num);
			borderTop.y = height;
			borderBot.y = -height;
			borderBot.border.clipGraphic(0, 0, borderBot.border.graphic.width, borderBot.border.graphic.height + height);
			borderTop.border.clipGraphic(0, -height, borderTop.border.graphic.width, borderTop.border.graphic.height + height);
			borderTop.border.offset.y = ogBorderOffsetY + height;

			for (i => thing in borderBot.members) {
				if (thing == borderBot.border || borderTop.border.frameHeight - 40 >= thing.y + thing.height - 5) {
					thing.visible = thing == borderBot.border;
					continue;
				}

				final y = Math.max((borderTop.border.frameHeight - 40) - thing.y, 0);
				thing.clipGraphic(0, y, thing.graphic.width, thing.graphic.height - y);
				thing.offset.y = ogOffsets[i] - y;
			}
		});
	}

	function changeDifficulty(dir:Int = 0) {
		diffNames.members[curDiffSelected].color = FlxColor.fromRGBFloat(diffColors[curDiffSelected][0], diffColors[curDiffSelected][1], diffColors[curDiffSelected][2], 1.0);
		diffNames.members[curDiffSelected].font = Paths.font("menus/GOTHIC.TTF");

		curDiffSelected = FlxMath.wrap(curDiffSelected + dir, 0, Difficulty.list.length - 1);
		diffSel.setPosition(diffBGs.members[curDiffSelected].x, diffBGs.members[curDiffSelected].y + diffBGs.members[curDiffSelected].height - diffSel.height);
		diffSel.colorTransform.alphaOffset = -117;

		diffNames.members[curDiffSelected].color = 0xFFFFFFFF;
		diffNames.members[curDiffSelected].font = Paths.font("menus/GOTHICB.TTF");

		var oldPoints:Array<Float> = [for (i in 0...diffPoints.length) diffPoints[i]];
		var finalPoints:Array<Float> = [];
		final songs = weekList[curSelected].songs;
		final diffIdx = (Settings.data.gameplayModifiers["playingSide"] == "Opponent") ? 1 : 0;
		final curDiff = (Settings.data.gameplayModifiers["playingSide"] == "Dancer") ? "Camellia" : Difficulty.list[curDiffSelected];
		curScore = 0;
		var allSongs = true;
		var acc = 1.0;
		for (i => song in songs) {
			final meta = Meta.load(song.id);
			final diffs = meta.rating.get(curDiff);
			final diffTxt = songDiffs.members[i];
			
			final score = Scores.get(song.id, Difficulty.list[curDiffSelected], meta.hasModchart);
			curScore += score.score;
			acc *= score.accuracy * 0.01;
			allSongs = allSongs && (score.accuracy >= 0);
			
			finalPoints.push((diffs == null || diffs.length < (diffIdx + 1)) ? 0 : Math.floor(diffs[diffIdx]) * 0.05);
			diffTxt.text = (diffs == null || diffs.length < (diffIdx + 1)) ? "?" : Std.string(Math.floor(diffs[diffIdx])) + (diffs[diffIdx] % 1 != 0 ? "+" : "");
			diffTxt.updateHitbox();
			diffTxt.clipGraphic(0, 0, diffTxt.graphic.width, diffTxt.graphic.height * 0.75);
			diffTxt.x = songBGs.members[i].x + songBGs.members[i].width - 5 - diffTxt.frameWidth;
		}

		if (Settings.data.reducedQuality)
			bestScore.text = Std.string(curScore);
		final rank:Ranking = allSongs ? Ranking.getFromAccuracy(acc * 100) : {};
		bestRank.text = rank.name;
		bestRank.color = rank.color;

		final splitWidth = (songs.length < 2) ? graph.width : graph.width / (songs.length - 1);
		if (graphTwn != null)
			graphTwn.cancel();

		graphTwn = FlxTween.num(0, 1, 0.35, {ease: FlxEase.quintOut, onComplete: function(twn) {
			graphTwn = null;
		}}, function(num) {
			for (i in 0...diffPoints.length)
				diffPoints[i] = FlxMath.lerp(oldPoints[i], finalPoints[i], num);

			if (Settings.data.shaders)
				graphShader.setPoints(diffPoints);

			for (i => dot in graphDots.members) {
				final height = graph.frameHeight * diffPoints[i] + 4.5;
				dot.clipGraphic(0, 0, dot.frameWidth, height + 1);
				dot.y = graph.y + graph.height - height;
			}
			for (i => line in graphLines.members) {
				if (graphLines.length == 1) {
					line.y = graph.y + graph.height * (1.0 - diffPoints[i]) - line.height * 0.5;
					continue;
				}
	
				final height1 = graph.height * diffPoints[i];
				final height2 = graph.height * diffPoints[i + 1];
				line.y = graph.y + graph.height - FlxMath.lerp(height1, height2, 0.5) - line.height * 0.5;
				line.angle = Math.atan((height1 - height2) / splitWidth) * FlxAngle.TO_DEG;
				line.scale.x = Math.sqrt(splitWidth * splitWidth + Math.pow(height2 - height1, 2));
			}
		});
	}

	function weekInputs() {
		final leftJustPressed:Bool = Controls.justPressed('ui_left');

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			if (graphTwn != null) {
				graphTwn.cancel();
				graphTwn = null;
			}

			final week = weekList[curSelected];
			FlxG.sound.play(Paths.audio("menu_cancel", 'sfx'));
			curSelected = -1;
			inTween = true;

			final halfDiv = 0.5 / songBGs.length;
			final diffDiv = 0.5 / diffBGs.length;
			final curAOffset = diffSel.colorTransform.alphaOffset;
			FlxTween.num(0.5, 0, 0.375, null, function(num) {
				diffSel.colorTransform.alphaOffset = FlxMath.lerp(-117, curAOffset, num * 2);
				for (i => bg in songBGs.members) {
					final name = songNames.members[i];
					final diff = songDiffs.members[i];

					bg.alpha = name.alpha = diff.alpha = FlxEase.cubeOut((num - halfDiv * i) / halfDiv);
					bg.offset.x = name.offset.x = diff.offset.x = -30 * (1.0 - bg.alpha);
				}
				for (j in 0...diffBGs.members.length) {
					final i = Difficulty.list.length - 1 - j;
					final bg = diffBGs.members[i];
					final name = diffNames.members[i];

					bg.alpha = name.alpha = FlxEase.quadIn(Math.min(Math.max((num - diffDiv * i) / diffDiv, 0.0), 1.0));
					bg.offset.y = name.offset.y = 15 * (1.0 - bg.alpha);
				}
			});

			final splitWidth = (diffPoints.length < 2) ? graph.width : graph.width / (diffPoints.length - 1);
			final curBanner = banners.members[curHover];
			final imgScale = curBanner.graphic.width / 640;
			final startScale = 640 / curBanner.graphic.width;
			final scale = FlxG.height / Math.min(360 * imgScale, curBanner.graphic.height - week.selectedClipY);

			FlxTween.num(0, 1, 0.75, {ease: FlxEase.quintInOut, type: BACKWARD, onComplete: function(twn) {
				while (graphDots.length > 0) {
					final dot = graphDots.members[0];
					graphDots.remove(dot, true);
					dot.destroy();
				}
				while (graphLines.length > 0) {
					final line = graphLines.members[0];
					graphLines.remove(line, true);
					line.destroy();
				}
				while (songBGs.length > 0) {
					final bg = songBGs.members[0];
					final name = songNames.members[0];
					final diff = songDiffs.members[0];

					songBGs.remove(bg, true);
					songNames.remove(name, true);
					songDiffs.remove(diff, true);
					bg.destroy();
					name.destroy();
					diff.destroy();
				}
				while (diffBGs.length > 0) {
					final bg = diffBGs.members[0];
					final name = diffNames.members[0];

					diffBGs.remove(bg, true);
					diffNames.remove(name, true);
					bg.destroy();
					name.destroy();
				}

				inTween = false;
			}}, function(num) {
				curBanner.scale.x = curBanner.scale.y = FlxMath.lerp(startScale, scale, num);
				final clipY = FlxMath.lerp(week.unselectedClipY, week.selectedClipY, num);
				curBanner.clipGraphic(0, clipY, curBanner.graphic.width, Math.min(FlxMath.lerp(190, 360, num) * imgScale, curBanner.graphic.height - clipY));
				curBanner.origin.set(curBanner.frameWidth * 0.5, curBanner.frameHeight * 0.5);
				curBanner.offset.copyFrom(curBanner.origin);

				for (i => dot in graphDots.members) {
					final height = graph.frameHeight * diffPoints[i] * num + 4.5;
					dot.clipGraphic(0, 0, dot.frameWidth, height + 1);
					dot.y = graph.y + graph.height - height;
				}
				for (i => line in graphLines.members) {
					if (graphLines.length == 1) {
						line.y = graph.y + graph.height * (1.0 - diffPoints[i] * num) - line.height * 0.5;
						continue;
					}
	
					final height1 = graph.height * diffPoints[i] * num;
					final height2 = graph.height * diffPoints[i + 1] * num;
					line.y = graph.y + graph.height - FlxMath.lerp(height1, height2, 0.5) - line.height * 0.5;
					line.angle = Math.atan((height1 - height2) / splitWidth) * FlxAngle.TO_DEG;
					line.scale.x = Math.sqrt(splitWidth * splitWidth + Math.pow(height2 - height1, 2));
				}
				if (Settings.data.shaders)
					graphShader.progress.value[0] = num;
			});

			FlxTween.tween(scoreBG.scale, {y: 0}, 0.25, {ease: FlxEase.cubeOut});
			FlxTween.num(1, 0, 0.25, {ease: FlxEase.cubeOut}, function(num) {
				graph.alpha = num;
				graphDots.alpha = num;
				graphLines.alpha = num;
				for (obj in [bestRank, rankTitle, bestTitle, bestScore]) {
					obj.alpha = num;
					obj.offset.y = 30 * (1 - num);
				}
			});
		} else if (leftJustPressed || Controls.justPressed('ui_right')) {
			changeDifficulty(leftJustPressed ? -1 : 1);
			FlxG.sound.play(Paths.audio("menu_setting_tick", 'sfx'));
		} else if (Controls.justPressed('accept'))
			confirmWeek();

		if (FlxG.mouse.y < diffBGs.members[0].y || FlxG.mouse.y > diffBGs.members[0].y + diffBGs.members[0].height) return;
		final xOffset = 42 * (1.0 - (FlxG.mouse.y - diffBGs.members[0].y) / diffBGs.members[0].height);

		for (i => bg in diffBGs.members) {
			if (FlxG.mouse.justReleased && !draggedOnce && FlxG.mouse.x >= bg.x + xOffset && FlxG.mouse.x <= bg.x + xOffset + (bg.width - 42)) {
				if (i != curDiffSelected) {
					changeDifficulty(i - curDiffSelected);
					FlxG.sound.play(Paths.audio("menu_setting_tick", 'sfx'));
				} else
					confirmWeek();
			}
		}
	}

	function loadWeeks() {
		add(banners = new FlxTypedGroup<FunkinSprite>());
		for (i => week in weekList) {
			final path = Paths.exists('images/menus/Story/weeks/${week.background}.png') ? week.background : 'BACKUP';
			var banner = new FunkinSprite(FlxG.width * 0.5 + 55 * (i - curHover), FlxG.height + 225 * (i - curHover), Paths.image('menus/Story/weeks/$path'));
			banner.clipGraphic(0, week.unselectedClipY, banner.graphic.width, Math.min((banner.graphic.width / 640) * 190, banner.graphic.height - week.unselectedClipY));
			banner.setGraphicSize(640);
			banner.updateHitbox();
			banner.offset.set(banner.frameWidth * 0.5, banner.frameHeight * 0.5);
			banner.alpha = 0.0;
			banner.color = (i == curHover) ? 0xFFFFFFFF : 0xFF808080;
			banners.add(banner);
		}
	}
}