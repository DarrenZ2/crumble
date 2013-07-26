package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	import starling.core.Starling;
	import flash.geom.Rectangle;

	[SWF(width="32", height="32", frameRate="30", backgroundColor="#000000")]
	public class Crumble extends Sprite
	{
		public static const frameRate:int = 30;
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
			
			stage.addEventListener(Event.RESIZE, onStageResize);
		}
		
		private function onStageResize(event:Event):void
		{
			var viewPortRectangle:Rectangle = new Rectangle();
			viewPortRectangle.width = stage.stageWidth;
			viewPortRectangle.height = stage.stageHeight;
			Starling.current.viewPort = viewPortRectangle;
			
			mStarling.stage.stageWidth = stage.stageWidth;
			mStarling.stage.stageHeight = stage.stageHeight;
		}
	}
}