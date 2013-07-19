package
{
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	public final class Background extends Sprite
	{
		private var quad:Quad;
		
		public function Background()
		{
			super();
			
			if (stage != null) {
				initialize(null);
			}
			else {
				addEventListener(Event.ADDED_TO_STAGE, initialize);
			}
		}
		
		private function initialize(event:Event):void
		{
			if (event != null) {
				removeEventListener(Event.ADDED_TO_STAGE, initialize);
			}

			quad = new Quad(stage.stageWidth, stage.stageHeight);
			quad.color = 0xff506880;
			addChild(quad);
		}
		
		private function onResize(event:ResizeEvent):void 
		{
			quad.x = 0;
			quad.y = 0;
			quad.width = event.width;
			quad.height = event.height;
		}
	}
}