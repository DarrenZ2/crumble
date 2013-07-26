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
		private var _terrainWidth:int;							public function get terrainWidth():int { return _terrainWidth; }
		private var _terrainHeight:int;							public function get terrainHeight():int { return _terrainHeight; }

		public function Terrain(space:Space, width:int, height:int)
		{
			super();
			
			this.space = space;
			_terrainWidth = width;
			_terrainHeight = height;
			
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
			terrainCollision = new BitmapData(_terrainWidth, _terrainHeight);
			terrainCollision.fillRect(terrainCollision.rect, 0xFFFF0000); // all solid
			
			// Construct visible terrain and mask out collision threshold beneath the isovalue, 0x80.
			var initialTerrainBitmap:BitmapData = new BitmapData(_terrainWidth, _terrainHeight);
			initialTerrainBitmap.fillRect(terrainCollision.rect, 0x00000000); // dirt color yo!
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
			terrain = new TerrainCache(terrainCollision, 64, 8);
			terrain.invalidate(new AABB(0, 0, _terrainWidth, _terrainHeight), space);
		}
		
		public function subtractCollision(stencil:Stencil, transform:Matrix):void
		{
			stencil.subtractFromBitmapData(transform, terrainCollision);
			
			// update dirty region in collision
			var region:Rectangle = RectangleHelpers.boundsFromTransformedRect(stencil.rect, transform);
			terrain.invalidate(AABB.fromRect(region), space);
		}
		
		public function subtractVisual(stencil:Stencil, transform:Matrix):void
		{
			stencil.subtractFromRenderTexture(transform, terrainTexture);
		}

		public function addCollision(stencil:Stencil, transform:Matrix):void
		{
			stencil.addToBitmapData(transform, terrainCollision);
			
			// update dirty region in collision
			var region:Rectangle = RectangleHelpers.boundsFromTransformedRect(stencil.rect, transform);
			terrain.invalidate(AABB.fromRect(region), space);
		}
		
		public function addVisual(stencil:Stencil, transform:Matrix):void
		{
			stencil.addToRenderTexture(transform, terrainTexture);
		}
	}
}