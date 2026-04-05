package funkin.modchart.mods;

class IncomingAngle extends BaseModifier {
    var incomingAngleX:ModifierValue;
    var incomingAngleY:ModifierValue;
    @:alias(incomingangle) var incomingAngleZ:ModifierValue;
    var incomingAngleXLANE:ModifierValue;
    var incomingAngleYLANE:ModifierValue;
    @:alias(incomingangleLANE) var incomingAngleZLANE:ModifierValue;

    public function new(parent:ModchartManager) {
        super(parent);
        priority = 900;
    }

    override function modifiesPosition(strumline:Int):Bool {return true;}
    override function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
        if (type == STRUM) return;

        pos.x -= field.members[lane].modchartPos.x;
        pos.y -= field.members[lane].modchartPos.y;
        pos.z -= field.members[lane].modchartPos.z;

        pos.rotate(incomingAngleX + incomingAngleXLANE, incomingAngleY + incomingAngleYLANE, incomingAngleZ + incomingAngleZLANE);

        pos.x += field.members[lane].modchartPos.x;
        pos.y += field.members[lane].modchartPos.y;
        pos.z += field.members[lane].modchartPos.z;
    }
}