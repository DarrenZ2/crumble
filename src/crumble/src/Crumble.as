package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import starling.core.Starling;

	[SWF(width="320", height="240", frameRate="60", backgroundColor="#000000")]
	public class Crumble extends Sprite
	{
		public static const frameRate:int = 60;
		private var mStarling:Starling;
		
		public function Crumble()
		{
			super();
			
			// These settings are recommended to avoid problems with touch handling
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
						
			// Create a Starling instance that will run the "Game" class
			Starling.multitouchEnabled = true;
			Starling.handleLostContext = true;
			mStarling = new Starling(Game, stage);
			mStarling.simulateMultitouch = true;
			mStarling.showStats = true;
			mStarling.start();
		}
	}
}