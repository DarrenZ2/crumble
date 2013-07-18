package
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import nape.dynamics.InteractionFilter;
	import nape.geom.AABB;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Polygon;
	import nape.space.Space;
	import nape.util.BitmapDebug;
	import nape.util.Debug;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
		
	public class Game extends Sprite
	{
		private static const spaceDebugOverlay:Boolean = false;
		private var accgrav:AccelerometerGravity;
		private var space:Space;
		private var debug:Debug;
		private var bouncyMaterial:Material;
		private var terrainCollision:BitmapData;
		private var terrainTexture:RenderTexture;
		private var terrain:TerrainCache;
		private var explosionFootprint:BitmapData;
		private var explosionFootprintImage:Image;
		private var bodyQueryCache:BodyList;
		private var terrainIsolation:InteractionFilter;
		
		public function Game()
		{
			super();
			
			bodyQueryCache = new BodyList();
			
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

			// Background for receiving touch events
			var bkgnd:Quad = new Quad(stage.stageWidth, stage.stageHeight);
			bkgnd.color = 0xff506880;
			addChild(bkgnd);

			space = new Space(Vec2.weak(0, 0));
			bouncyMaterial = new Material(1.2);
			
			if (AccelerometerGravity.isSupported) {
				accgrav = new AccelerometerGravity();
				accgrav.space = space;
			}
			else {
				space.gravity = Vec2.weak(0, 600);
			}
			
			if (spaceDebugOverlay) {
				debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, stage.color);
				Starling.current.nativeOverlay.addChild(debug.display);
			}

			setup();

			// Construct collision mask for visible terrain.
			terrainCollision = new BitmapData(stage.stageWidth, stage.stageHeight);
			applyTerrainPerlin(terrainCollision, BitmapDataChannel.RED); // collision is pulled from the red channel
			
			// Construct visible terrain and mask out collision threshold beneath the isovalue, 0x80.
			var initialTerrainBitmap:BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight);
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
			
			const explosionFootprintRadius:Number = 25;
			var explosionShape:Shape = new Shape();
			explosionShape.graphics.beginFill(0xffffff, 1.0);
			explosionShape.graphics.drawCircle(explosionFootprintRadius, explosionFootprintRadius, explosionFootprintRadius);
			explosionShape.graphics.endFill();
			explosionFootprint = new BitmapData(explosionFootprintRadius*2, explosionFootprintRadius*2, true, 0);
			explosionFootprint.draw(explosionShape);
			var explosionFootprintTexture:Texture = Texture.fromBitmapData(explosionFootprint, false, true, 1);
			explosionFootprintImage = new Image(explosionFootprintTexture);
			
			terrain = new TerrainCache(terrainCollision, 30, 5);
			terrain.invalidate(new AABB(0, 0, stage.stageWidth, stage.stageHeight), space);

			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private static function applyTerrainPerlin(bitmap:BitmapData, channelFlags:uint):void
		{
			bitmap.perlinNoise(200, 200, 3, 0x3ed, false, true, channelFlags, false);
		}
		
		public function explodeAt(pos:Point):void
		{
			const _pos:Vec2 = Vec2.weak(pos.x - explosionFootprint.width/2, pos.y - explosionFootprint.height/2);
			
			// Update visual.
			explosionFootprintImage.blendMode = BlendMode.ERASE;
			terrainTexture.draw(explosionFootprintImage, new Matrix(1, 0, 0, 1, _pos.x, _pos.y)); 

			// Subtract from collision.
			terrainCollision.draw(explosionFootprint, new Matrix(1, 0, 0, 1, _pos.x, _pos.y), null, BlendMode.SUBTRACT);
			
			// Invalidate region of terrain collision effected.
			var region:AABB = AABB.fromRect(explosionFootprint.rect);
			region.x += _pos.x;
			region.y += _pos.y;
			
			terrain.invalidate(region, space);
		}

		private function setup():void 
		{
			var w:int = stage.stageWidth;
			var h:int = stage.stageHeight;
			
			// Physical scene
			var floor:Body = new Body(BodyType.STATIC);
			floor.shapes.add(new Polygon(Polygon.rect( 0,  h, w, 1)));
			floor.shapes.add(new Polygon(Polygon.rect( 0, -1, w, 1)));
			floor.shapes.add(new Polygon(Polygon.rect( w,  0, 1, h)));
			floor.shapes.add(new Polygon(Polygon.rect(-1,  0, 1, h)));
			floor.space = space;
		}
		
		private function onEnterFrame(event:EnterFrameEvent):void
		{
			space.step(1 / Crumble.frameRate);
	
			space.liveBodies.foreach(function(b:Body) : void {
				var graphic:DisplayObject = b.userData.graphic;
				graphic.x = b.position.x; 
				graphic.y = b.position.y;
				graphic.rotation = b.rotation;
			});
			
			if (spaceDebugOverlay) {
				debug.clear();
				debug.draw(space);
				debug.flush();
			}
		}
		
		private function spawnBoxAt(pos:Point):void
		{
			var w:Number = 15;
			var h:Number = 15;

			var quad:Quad = new Quad(w, h);
			quad.pivotX = w/2;
			quad.pivotY = h/2;
			quad.color = 0xffff00ff;
			addChild(quad);
			
			var box:Body = new Body(BodyType.DYNAMIC);
			box.shapes.add(new Polygon(Polygon.box(w, h)));
			box.setShapeMaterials(bouncyMaterial);
			box.position.setxy(pos.x, pos.y); 
			box.userData.graphic = quad;
			space.bodies.add(box);
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.BEGAN);
			for each (var touch:Touch in touches)
			{
				var pos:Point = touch.getLocation(this);
				bodyQueryCache.clear();
				space.bodiesUnderPoint(Vec2.fromPoint(pos, true),  null, bodyQueryCache);
				
				var hitTerrain:Boolean = false;
				for (var i:int = 0; i < bodyQueryCache.length && !hitTerrain; i++) {
					if (bodyQueryCache.at(i).isStatic()) {
						hitTerrain = true;
					}
				}
				
				if (hitTerrain) {
					explodeAt(pos);
				}
				else {
					spawnBoxAt(pos);
				}
			}
		}
	}
}