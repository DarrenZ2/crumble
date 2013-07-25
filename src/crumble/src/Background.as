package
{
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public final class Background extends Sprite
	{
		private var quad:Quad;
		private var radius:Number;
		
		public function Background(radius:Number)
		{
			super();
			this.radius = radius;
			
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

			quad = new Quad(radius*2, radius*2);
			quad.color = 0xff506880;
			addChild(quad);
		}
	}
}