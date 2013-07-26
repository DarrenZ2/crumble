package
{
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	public final class Background extends Sprite
	{
		[Embed(source="bg1.png")]
		private static const Background1:Class;

		[Embed(source="bg2.png")]
		private static const Background2:Class;

		private var image:Image;
		
		public function Background(radius:Number)
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

			var Background:Class = (Math.random() > 0.5) ? Background1 : Background2;
			var tex1:Texture = Texture.fromBitmap(new Background());
			image = new Image(tex1);
			addChild(image);
		}
	}
}