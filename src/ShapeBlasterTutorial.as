package
{
	import org.flixel.*;
	import flash.display.StageQuality;
	[SWF(width="800", height="600", backgroundColor="#888888")]
	
	public class ShapeBlasterTutorial extends FlxGame
	{
		public function ShapeBlasterTutorial()
		{
			super(800, 600, ScreenState, 1.0, 60, 60, true);
			
			forceDebugger = true;
			useSystemCursor = false;
			stage.quality = StageQuality.LOW;
		}
	}
}