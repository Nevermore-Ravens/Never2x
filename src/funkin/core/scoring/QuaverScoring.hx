package funkin.core.scoring;

// https://github.com/Quaver/Quaver.API/blob/master/Quaver.API/Maps/Processors/Scoring/ScoreProcessorKeys.cs#106
// https://github.com/Quaver/Quaver.API/blob/master/Quaver.API/Maps/Processors/Scoring/ScoreProcessorKeys.cs#185
// https://github.com/Quaver/Quaver.API/blob/master/Quaver.API/Maps/Processors/Scoring/ScoreProcessorKeys.cs#407
//
// this is supposed to count up from 0
// but instead does the opposite ?????
// what the fuck
class QuaverScoring extends ScoreHandler {
	var current:Int = 0;
	public function new() {
		super('Quaver');
	}

	override function getWeight(deviation:Float):Float {
		var id:Int = Judgement.getID(deviation);

		return switch id {
			default: 0;

			case 0: 100;
			case 1: 50;
			case 2: 25;
			case 3: 10;
			case 4: 5;
		}
	}

	var multiplierCount:Int = 0;
	var multiplierCountToIncreaseIndex:Int = 10;
	var maxMultiplierCount(get, never):Int;
	function get_maxMultiplierCount():Int {
		return multiplierMaxIndex * multiplierCountToIncreaseIndex;
	}

	var multiplierMaxIndex:Int = 15;
	var multiplierIndex:Int = 0;

	var scoreCount:Int = 0;
	var summedScore:Int = 0;

	var mineCount:Int = 0;
	var notesHit:Int = 0;
	var misses:Int = 0;

	override function noteHit(note:Note, ?deviation:Float) {
		deviation ??= note.getDeviation();

		// where the fuck is this supposed to be called ??????
		summedScore = calculateSummedScore();

		if (note.behavior.punishable)
			mineCount++;

		notesHit++;

		// we don't have combo break judgements so 
		// lol
		var windowID:Int = Judgement.getID(deviation);

		if (windowID == 3)
			multiplierCount -= multiplierCountToIncreaseIndex;
		else 
			multiplierCount++;

		// Make sure the multiplier count doesn't go below 0
		if (multiplierCount < 0)
			multiplierCount = 0;
		// Make sure the multiplier count is not over max multiplier count
		else if (multiplierCount > maxMultiplierCount)
			multiplierCount = maxMultiplierCount;

		// Update multiplier index and score count.
		multiplierIndex = Math.floor(multiplierCount / multiplierCountToIncreaseIndex);
		scoreCount += Std.int(getWeight(deviation)) + multiplierIndex * multiplierCountToIncreaseIndex;

		// Update total score.
		final standardizedMaxScore:Float = 1000000;
		current = Std.int(standardizedMaxScore * (scoreCount / summedScore));
	}

	override function noteMissed(_) {
		misses++;
		summedScore = calculateSummedScore();
	}

	override function sustainDropped(_) {
		misses++;
		summedScore = calculateSummedScore();
	}

	function calculateSummedScore():Int {
		var summedScore = 0;

		// Multiplier doesn't increase after this amount.
		var maxMultiplierCount = multiplierMaxIndex * multiplierCountToIncreaseIndex;

        // The total number of judgements for a maximum score would be excluding the number of mines.
        // This is because both a mine hit (a miss) and a mine clear (nothing) will gain 0 point,
        // but a mine hit resets combo, reducing score.
		var totalJudgements = (notesHit + misses) - mineCount;

        // Calculate score for notes below max multiplier combo
        // Note: This block could be a constant for songs that have max combo that exceeds the max multiplier count, but that will mean we will have to manually change the constant everytime we update any single other constant.
		//
		// i know quaver does a for loop here but i cannot understand
		// how to convert c# for loops to haxe for loops
		var i:Int = 1;
		while (i <= totalJudgements && i < maxMultiplierCount) {
			summedScore += Std.int(getWeight(0)) + multiplierCountToIncreaseIndex * Math.floor(i / multiplierCountToIncreaseIndex);
			i++;
		}

		// Calculate score for notes once max multiplier combo is reached
		//
		// thank you quaver for using 2 different variables with the EXACT same name other than a capitalized T
		if ((notesHit + misses) >= maxMultiplierCount)
			summedScore += ((notesHit + misses) - (maxMultiplierCount - 1)) * (Std.int(getWeight(0)) + maxMultiplierCount);

		return summedScore;
	}

	override function get(_):Int return current;
}