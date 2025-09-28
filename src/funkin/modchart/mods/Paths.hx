package funkin.modchart.mods;

class Paths extends BaseModifier {

	inline function sin(rads:Float, clip:Float){
		var value = FlxMath.fastSin(rads);
		var sign = value / Math.abs(value);
		if(Math.abs(value) > Math.abs(clip))return Math.abs(clip) * sign;
		return value;
	}

	inline function triangle(angle:Float) {
		var fAngle:Float = angle % (Math.PI * 2.0);
		if (fAngle < 0.0)
			fAngle += Math.PI * 2.0;
		
		var result:Float = fAngle / Math.PI;
		
		if (result < 0.5) {
			return 2.0 * result;
		}
		else if (result < 1.5) {
			return -2.0 * result + 2.0;
		}
		else {
			return 2.0 * result - 4.0;
		}
	}

	inline function getDigitalAngle(yOffset:Float, offset:Float, period:Float) {
		return Math.PI * (yOffset + (1 * offset)) / (Strumline.swagWidth + (period * Strumline.swagWidth));
	}

    public function new(parent:ModchartManager) {
        super(parent);
        priority = 20;
    }

	// TODO: dont hardcode this shit
	inline function getXOffset(lane:Int){
		return switch(lane){
			case 0: -Strumline.swagWidth * 1.5;
			case 1: -Strumline.swagWidth * 0.5;
			case 2: Strumline.swagWidth * 0.5;
			case 3: Strumline.swagWidth * 1.5;
			default: 0;
		};
	}

	override public function modifiesDistance(strumline:Int) {return true;}
	override function adjustDistance(spr:FunkinSprite, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {

		final cubicY: Float = getValue(CUBIC_Y_INDEX, strumline);
		if(cubicY != 0)
			distance += cubicY * Math.pow((getValue(CUBIC_Y_OFFSET_INDEX, strumline) + distance) / Strumline.swagWidth, 3);
		
		final parabolaY: Float = getValue(PARABOLA_Y_INDEX, strumline);
		if(parabolaY != 0){
			final factor: Float = (getValue(PARABOLA_Y_OFFSET_INDEX, strumline) + distance) / Strumline.swagWidth;
			distance += parabolaY * factor * factor;
		}

		
		return distance;
	}

    override public function modifiesPosition(strumline:Int) {return true;}
    override public function adjustPos(spr:FunkinSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, beat:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		// Gets the distance value based on if PATHS_USE_PATH_Y is enabled or not
		// When enabled, then paths will use pos.y to determine where in the path it is
		// When disabled, paths use distance.
		// Doing it in a function so paths that modify the Y are also taken into account here
		
		final sinClip:Float = Math.abs(1 - parent.get("sinclip", strumline));

		var usedDistance:Float = getValue(PATHS_USE_PATH_Y, strumline) == 1 ? distance : unadjustedDistance;

		pos.x += getValue(XMODE_INDEX, strumline) * usedDistance * (strumline % 2 == 0 ? 1 : -1);
		final zigzag:Float = getValue(ZIGZAG_INDEX, strumline);
		if (zigzag != 0) {
			final offset: Float = getValue(ZIGZAG_OFFSET_INDEX, strumline);
			final period: Float = getValue(ZIGZAG_PERIOD_INDEX, strumline);
			final result: Float = triangle((Math.PI * (1 / (period + 1)) * ((usedDistance + 100 * offset) / Strumline.swagWidth)));

			pos.x += (zigzag * (Strumline.swagWidth * 0.5)) * result;
		}

		final digital = getValue(DIGITAL_INDEX, strumline);
		if(digital != 0){
			final steps: Float = getValue(DIGITAL_STEPS_INDEX, strumline) + 1;
			final period: Float = getValue(DIGITAL_PERIOD_INDEX, strumline);
			final offset: Float = getValue(DIGITAL_OFFSET_INDEX, strumline);

			pos.x += (digital * (Strumline.swagWidth * 0.5)) * Math.round(steps * sin(getDigitalAngle(usedDistance, offset, period), sinClip)) / steps;
		}

		final cubic: Float = getValue(CUBIC_X_INDEX, strumline);
		if(cubic != 0)
			pos.x += cubic * Math.pow((getValue(CUBIC_X_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth, 3);

		final cubicZ: Float = getValue(CUBIC_Z_INDEX, strumline);
		if(cubicZ != 0)
			pos.z += cubicZ * Math.pow((getValue(CUBIC_Z_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth, 3);

		final parabola: Float = getValue(PARABOLA_X_INDEX, strumline);
		if(parabola != 0){
			final factor: Float = (getValue(PARABOLA_X_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.x += parabola * factor * factor;
		}

		final parabolaZ: Float = getValue(PARABOLA_Z_INDEX, strumline);
		if(parabolaZ != 0){
			final factor: Float = (getValue(PARABOLA_Z_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.z += parabolaZ * factor * factor;
		}
		
		var xOffset: Float = getXOffset(lane);

		final attenuateX: Float = getValue(ATTENUATE_INDEX, strumline);
		if(attenuateX != 0){
			final attenuateFactor: Float = (getValue(ATTENUATE_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.x += attenuateX * attenuateFactor * attenuateFactor * (xOffset / Strumline.swagWidth);
		}

		final attenuateY: Float = getValue(ATTENUATE_Y_INDEX, strumline);
		if(attenuateY != 0){

			final attenuateFactor: Float = (getValue(ATTENUATE_Y_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.y += attenuateY * attenuateFactor * attenuateFactor * (xOffset / Strumline.swagWidth);
		}

		final attenuateZ: Float = getValue(ATTENUATE_Z_INDEX, strumline);
		if(attenuateZ != 0){
			final attenuateFactor: Float = (getValue(ATTENUATE_Z_OFFSET_INDEX, strumline) + usedDistance) / Strumline.swagWidth;
			pos.z += attenuateZ * attenuateFactor * attenuateFactor * (xOffset / Strumline.swagWidth);
		}
    }

    override public function addStrumlineSet() {
        super.addStrumlineSet();
        values.push([for(i in 0...PATHS_USE_PATH_Y + 1) 0.0]);
    }


    public static inline var XMODE_INDEX:Int = 0;
    public static inline var ZIGZAG_INDEX:Int = 1;
	public static inline var ZIGZAG_OFFSET_INDEX:Int = 2;
	public static inline var ZIGZAG_PERIOD_INDEX:Int = 3;

	public static inline var DIGITAL_INDEX:Int = 4;
	public static inline var DIGITAL_OFFSET_INDEX:Int = 5;
	public static inline var DIGITAL_PERIOD_INDEX:Int = 6;
	public static inline var DIGITAL_STEPS_INDEX:Int = 7;
	public static inline var CUBIC_X_INDEX:Int = 8;
	public static inline var CUBIC_X_OFFSET_INDEX:Int = 9;
	public static inline var CUBIC_Y_INDEX:Int = 10;
	public static inline var CUBIC_Y_OFFSET_INDEX:Int = 11;
	public static inline var CUBIC_Z_INDEX:Int = 12;
	public static inline var CUBIC_Z_OFFSET_INDEX:Int = 13;
	
	public static inline var PARABOLA_X_INDEX:Int = 14;
	public static inline var PARABOLA_X_OFFSET_INDEX:Int = 15;
	public static inline var PARABOLA_Y_INDEX:Int = 16;
	public static inline var PARABOLA_Y_OFFSET_INDEX:Int = 17;
	public static inline var PARABOLA_Z_INDEX:Int = 18;
	public static inline var PARABOLA_Z_OFFSET_INDEX:Int = 19;

	public static inline var ATTENUATE_INDEX:Int = 20;
	public static inline var ATTENUATE_OFFSET_INDEX:Int = 21;

	public static inline var ATTENUATE_Y_INDEX:Int = 22;
	public static inline var ATTENUATE_Y_OFFSET_INDEX:Int = 23;

	public static inline var ATTENUATE_Z_INDEX:Int = 24;
	public static inline var ATTENUATE_Z_OFFSET_INDEX:Int = 25;

	public static inline var PATHS_USE_PATH_Y = 26;

    public static function attachToRedirects() {
		var modifiers: Array<String> = [
			"xmode", 
			"zigzag", 
			"zigzagoffset", 
			"zigzagperiod", 
			"digital", 
			"digitaloffset", 
			"digitalperiod", 
			"digitalsteps", 
			"cubicx", 
			"cubicxoffset", 
			"cubicy",
			"cubicyoffset",
			"cubicz",
			"cubiczoffset",
			"parabolax", 
			"parabolaxoffset", 
			"parabolay",
			"parabolayoffset",
			"parabolaz",
			"parabolazoffset",
			"attenuate",
			"attenuateoffset",
			"attenuatey",
			"attenuateyoffset",
			"attenuatez",
			"attenuatezoffset",
			"pathtype" // TODO: maybe figure out a new name, but TL;DR similar to stealthtype where if its 1 then paths will use pos.y instead of distance
			// maybe this should be an aux mod in modmanager that every path mod that requires note's y pos follows? we should also add stealthtype lol
		];

		for(idx in 0...modifiers.length)
			ModchartManager.defaultRedirects.set(modifiers[idx], {toClass: Paths, index: idx});

		// Aliases
		ModchartManager.defaultRedirects.set("attenuatex", {toClass: Paths, index: ATTENUATE_INDEX});
		ModchartManager.defaultRedirects.set("attenuatexoffset", {toClass: Paths, index: ATTENUATE_OFFSET_INDEX});

		

    }
}