package funkin.states;

@:structInit
@:publicFields
class Preset {
	var name:String = 'Default';
	var description:String = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
	
	var onAccept:Void -> Void = function() {};
}

class StartupState extends FlxState {
	var introMessage:String = "Hey there!\nNever2x is a bit unique for a FNF fork, and is more akin to StepMania or Etterna-like VSRG's.\nThis might make it seem overwhelming for those playing this for the first time, whether you come from FNF, StepMania, or this is your first time playing a rhythm game at all.\nTo ease you into Never2x, let's pick a preset first.\nIf you don't want a preset and want to start playing immediately, just hit Escape on your keyboard.";
	var introText:FlxText;

	var presetGroup:FlxTypedSpriteGroup<FlxText>;
	var presetHeader:FlxText;
	var presetText:FlxText;
	var presetDescription:FlxText;
	
	var presets:Array<Preset> = [
		{
			name: 'Beginner',
			description: 'This is my first time playing a rhythm game.',
			onAccept: function() {
				Settings.data.scrollSpeed = 2.5;
				Settings.data.hitErrorBar = false;
				Settings.data.holdGrain = 10;
			}
		},
		{
			name: 'FNF Player',
			description: 'I regularly play FNF and nothing else.',
			onAccept: function() {
				Settings.data.hitErrorBar = false;
				Settings.data.holdGrain = 10;
			}
		},
		{
			name: 'StepMania Player',
			description: 'I regularly play games like StepMania.',
			onAccept: function() {
				Settings.data.noteSplashSkin = 'none';
				Settings.data.quantColouring = 'StepMania';
				Settings.data.strumGlow = 'Judgement';
				Settings.data.comboTinting = 'Judgement';
				Settings.data.cameraZooms = 'Off';
				
				// why aren't these working properly ??????
				Settings.data.simplePopup = true;
				Settings.data.popupOnField = true;
				Settings.data.popupPosSafety = true;
				Settings.data.judgementPos = [640, 360];
				Settings.data.comboPos = [640, 420];
				Settings.data.judgementCounter = true;
				Settings.data.gameVisibility = 50;
				Settings.data.holdGrain = 10;
			}
		},
		{
			name: 'Modcharting',
			description: "Modcharting (like NotITG) is my forte.\n\n\n(assumes your PC isn't dogshit)",
			onAccept: function() {
				Settings.data.quantColouring = 'In The Groove';
				Settings.data.noteSplashSkin = 'none';
				Settings.data.holdGrain = 1;
				Settings.data.hideHUD = true;
				Settings.data.simplePopup = true;
				Settings.data.cameraZooms = 'Off';
				Settings.data.centeredNotes = true;
			}
		},
		{
			name: 'Casual',
			description: 'I just like hitting notes, not much else to it.',
			onAccept: function() {
				Settings.data.hitErrorBar = false;
			}
		},
		{
			name: 'Competitive',
			description: "I try to achieve the best score on everything that I possibly can.",
			onAccept: function() {
				Settings.data.noteSplashSkin = 'None';
				Settings.data.judgementCounter = true;
				Settings.data.hideTightestJudge = true;
				Settings.data.gameVisibility = 0;
				Settings.data.healthBarAlpha = 0;
				Settings.data.simplePopup = true;
				Settings.data.popupOnField = true;
				Settings.data.judgementPos = [640, 360];
				Settings.data.comboPos = [640, 420];
			}
		}
	];

	var curSelected:Int = 0;

	override function create():Void {
		add(introText = new FlxText(0, 0, FlxG.width - 100, introMessage, 20));
		introText.font = Assets.getPath('fonts/LineSeed.ttf');
		introText.alignment = 'center';
		introText.screenCenter();

		add(presetGroup = new FlxTypedSpriteGroup<FlxText>());
		presetGroup.alpha = 0;

		presetGroup.add(presetHeader = new FlxText(0, 150, FlxG.width - 500, 'Pick a preset', 30));
		presetHeader.font = Assets.getPath('fonts/LineSeed.ttf');
		presetHeader.alignment = 'center';
		presetHeader.screenCenter(X);

		presetGroup.add(presetText = new FlxText(0, 0, FlxG.width, '', 40));
		presetText.font = Assets.getPath('fonts/LineSeed.ttf');
		presetText.alignment = 'center';
		presetText.screenCenter();

		presetGroup.add(presetDescription = new FlxText(0, FlxG.height - 200, FlxG.width - 200, '', 25));
		presetDescription.font = Assets.getPath('fonts/LineSeed.ttf');
		presetDescription.alignment = 'center';
		presetDescription.screenCenter(X);

		changeSelection();
	}

	function changeSelection(?direction:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + direction, 0, presets.length - 1);

		var curPreset = presets[curSelected];
		presetText.text = '< ${curPreset.name} >';
		presetDescription.text = curPreset.description;

		FlxG.sound.play(Assets.audio('sfx/scroll.ogg'));
	}

	var inputs:Bool = true;
	var inPresets:Bool = false;
	override function update(_) {
		if (!inputs) return;

		var pressedLeft:Bool = FlxG.keys.justPressed.LEFT;
		if (pressedLeft || FlxG.keys.justPressed.RIGHT) {
			changeSelection(pressedLeft ? -1 : 1);
		}

		if (FlxG.keys.justPressed.ESCAPE && !inPresets) {
			inputs = false;
			FlxG.sound.play(Assets.audio('sfx/cancel.ogg'));
			FlxTween.tween(introText, {alpha: 0}, 0.75, {
				ease: FlxEase.cubeIn,
				onComplete: function(_) {
					FlxG.switchState(new TitleState());
				}
			});	
		}

		if (FlxG.keys.justPressed.ENTER) {
			inputs = false;

			if (inPresets) {
				presets[curSelected].onAccept();

				FlxG.sound.play(Assets.audio('sfx/confirmhalf.ogg'));
				FlxG.camera.flash(0x99FFFFFF, 0.5);
				FlxTween.tween(presetGroup, {alpha: 0}, 0.75, {
					ease: FlxEase.cubeOut,
					onComplete: function(_) {
						FlxG.switchState(new TitleState());
					}
				});
			} else {
				FlxTween.tween(introText, {alpha: 0}, 0.5, {
					onComplete: function(_) {
						inPresets = true;
						introText.alpha = 0;
		
						FlxTween.tween(presetGroup, {alpha: 1}, 0.5, {
							ease: FlxEase.cubeOut,
							onComplete: function(_) {
								inputs = true;
							}
						});
					}
				});
			}
		}
	}
}