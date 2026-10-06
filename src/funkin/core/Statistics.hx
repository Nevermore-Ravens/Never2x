package funkin.core;

@:structInit
@:publicFields
class NoteHitData {
	var time:Int = 0;
	var deviation:Float = 0;
	var countMean:Bool = true;
}

@:structInit
@:publicFields
class Statistics {
	var fails:Int = 0;

	var score:Int = 0;
	var comboBreaks:Int = 0;
	var accuracy:Float = 0.0;
	var combo:Int = 0;
	var highestCombo:Int = 0;
	var notesHit:Int = 0;

	// not calculated until the song ends
	var mean:Float = 0.0; 
	var standardDeviation:Float = 0.0;

	var accuracyType:String = 'Unknown';
	var scoringType:String = 'Unknown';
	
	var noteHits:Array<NoteHitData> = [];
}