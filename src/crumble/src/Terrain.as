package
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import nape.geom.AABB;
	import nape.space.Space;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	
	public final class Terrain extends Sprite
	{
		private var space:Space;
		private var terrain:TerrainCache;
		private var terrainCollision:BitmapData;
		private var terrainTexture:RenderTexture;

		public function Terrain(space:Space)
		{
			super();
			
			this.space = space;
			
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
			
			// Construct collision mask for visible terrain.
			var hackWidth:int = 512; // TODO: Replace with bitmap inputs in constructor
			var hackHeight:int = 512;
			terrainCollision = new BitmapData(hackWidth, hackHeight);
			applyTerrainPerlin(terrainCollision, BitmapDataChannel.RED); // collision is pulled from the red channel
			
			// Construct visible terrain and mask out collision threshold beneath the isovalue, 0x80.
			var initialTerrainBitmap:BitmapData = new BitmapData(terrainCollision.width, terrainCollision.height);
			applyTerrainPerlin(initialTerrainBitmap, 7);
			initialTerrainBitmap.threshold(terrainCollision, initialTerrainBitmap.rect, new Point(0, 0), "<", 0x00800000, 0x00000000, 0x00FF0000, false);
			var initialTerrainTexture:Texture = Texture.fromBitmapData(initialTerrainBitmap, false);
			var initialTerrainImage:Image = new Image(initialTerrainTexture);
			terrainTexture = new RenderTexture(initialTerrainBitmap.width, initialTerrainBitmap.height);
			terrainTexture.draw(initialTerrainImage);
			initialTerrainImage.dispose();
			initialTerrainTexture.dispose();
			initialTerrainBitmap.dispose();
			var terrainImage:Image = new Image(terrainTexture);
			addChild(terrainImage);

			// Add logical terrain. This handles the transformation of bitmap to collidable bodies.
			terrain = new TerrainCache(terrainCollision, 30, 5);
			terrain.invalidate(new AABB(0, 0, stage.stageWidth, stage.stageHeight), space);
		}
		
		private static function applyTerrainPerlin(bitmap:BitmapData, channelFlags:uint):void
		{
			bitmap.perlinNoise(200, 200, 3, 0x3ed, false, true, channelFlags, false);
		}
		
		public function subtractStencil(stencil:Stencil, transform:Matrix):void
		{
			stencil.subtractFromBitmapData(transform, terrainCollision);
			stencil.subtractFromRenderTexture(transform, terrainTexture);

			// update dirty region in collision
			var region:Rectangle = RectangleHelpers.boundsFromTransformedRect(stencil.rect, transform);
			terrain.invalidate(AABB.fromRect(region), space);
		}
	}
}