package funkin.states;
import flixel.math.FlxPoint;

class BlueBalledState extends flixel.FlxSubState {
    var char:funkin.objects.Character;
    var song:String;

    var bg:FlxSprite;

    var camPos:FlxPoint;
	var camPointer:FlxObject;

    var confirm:Bool = false;

    var charID:Int;

    public function new(cam:FlxCamera, charID:Int = 0) {
        this.charID = charID;
        this.camera = cam;
        super();
        add(bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK));
        bg.scrollFactor.set(0, 0);
        bg.moves = false;
        bg.active = false;

        final ps = funkin.states.PlayState.self;
        final strums = ps.playfield.strumlines;
        char = ps.bf;//(charID < strums.length && strums.members[charID].character() != null) ? strums.members[charID].character() : ps.bf;
        char.dead = true;
        char.screenCenter();
        add(char);

        camPos = new FlxPoint(char.getGraphicMidpoint().x, char.getGraphicMidpoint().y);
        camera.target = null;
		add(camPointer = new FlxObject(0, 0, 1, 1));
        //camPos.set(char.getGraphicMidpoint().x, char.getGraphicMidpoint().y);
        camPointer.setPosition(camera.scroll.x + (FlxG.camera.width / 2), camera.scroll.y + (FlxG.camera.height / 2));
        camera.follow(camPointer, LOCKON, 1);

        char.playAnim('firstDeath');

        FlxG.sound.play(Assets.audio("sfx/menu_deletedata"));
        new FlxTimer().start(1.2, _ -> {
            Conductor.inst = FlxG.sound.load(Assets.audio("music/zenith"), 0.5, true);
            Conductor.inst.pitch = 1;
			Conductor.inst.play();
            char.playAnim('death-loop');
        });
    }

    override function update(t:Float){
        super.update(t);
        if(confirm) return;
        //trace("pointer pos: X:"+camPointer.x + " Y:"+camPointer.y);
        camPos.x = char.x + char.origin.x - char.frameOffset.x;
        camPos.y = char.x + char.origin.x - char.frameOffset.y;
        camPointer.setPosition(FlxMath.lerp(camPointer.x, camPos.x, 0.85), 
                               FlxMath.lerp(camPointer.y, camPos.y, 0.85));

        if (Controls.justPressed('accept')){
            Conductor.stop();
            FlxG.sound.play(Assets.audio("sfx/menu_confirm"));
            char.playAnim('confirm');
            ending();
        }
        else if (Controls.justPressed('back')){
            Conductor.stop();
            FlxG.sound.play(Assets.audio("sfx/byebye"));
            char.playAnim('missUP');
            backToMenu();
        }
    }

    function ending():Void{
        confirm = true;
        new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FunkinState.resetState();
				});
			});
    }

    function backToMenu():Void {
        confirm = true;
        new FlxTimer().start(0.7, function(tmr:FlxTimer){
            camera.fade(FlxColor.BLACK, 2, false, function()
            {
                /*if(funkin.states.PlayState.storyMode)
                    FlxG.switchState(new funkin.states.StoryMenuState());
                else
                    FlxG.switchState(new funkin.states.FreeplayState());*/
            });
        });
    }
}