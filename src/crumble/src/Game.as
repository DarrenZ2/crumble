package
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
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
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
		
	public final class Game extends Sprite
	{
		private static const spaceDebugOverlay:Boolean = false;
		private var background:Background;
		private var gravity:IGravity;
		private var border:Body;
		private var space:Space;
		private var debug:Debug;
		private var bouncyMaterial:Material;
		private var debugStencil:Stencil;
		private var bodyQueryCache:BodyList;
		private var terrain:Terrain;
		
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
		
		private static function createBorderBody(bounds:Rectangle):Body
		{
			var x1:int = bounds.x;
			var y1:int = bounds.y;
			var x2:int = bounds.right;
			var y2:int = bounds.bottom;
			
			var b:Body = new Body(BodyType.STATIC);
			b.shapes.add(new Polygon(Polygon.rect(x1  , y2  , x2  , y1+1)));
			b.shapes.add(new Polygon(Polygon.rect(x1  , y1-1, x2  , y1+1)));
			b.shapes.add(new Polygon(Polygon.rect(x2  , y1  , x1+1, y2  )));
			b.shapes.add(new Polygon(Polygon.rect(x1-1, y1  , x1+1, y2  )));
			
			return b;
		}
		
		private function initialize(event:Event):void
		{
			if (event != null) {
				removeEventListener(Event.ADDED_TO_STAGE, initialize);
			}

			var background:Background = new Background();
			addChild(background);
			
			space = new Space(Vec2.weak(0, 0));
			bouncyMaterial = new Material(1.2);

			// gravity
			space.gravity = new Vec2(0, 600);
			//gravity = new PointGravity(space, new Vec2(stage.stageWidth/2, stage.stageHeight/2));
			gravity = new AccelerometerGravity(space);

			if (spaceDebugOverlay) {
				debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, stage.color);
				Starling.current.nativeOverlay.addChild(debug.display);
			}

			// border prevents objects from leaving the stage
			border = createBorderBody(stage.bounds);
			border.space = space;

			// terrain
			terrain = new Terrain(space);
			addChild(terrain);
			
			// a debug stencil for punching out holes
			debugStencil = Stencil.createDebugCircle(30);

			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onEnterFrame(event:EnterFrameEvent):void
		{
			var dt:Number = 1 / Crumble.frameRate;
			
			if (gravity != null) {
				gravity.preFrameUpdate(dt);
			}
			
			space.step(dt);
			
			space.liveBodies.foreach(function(b:Body):void {
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
		
		public function explodeAt(pos:Point):void
		{
			var transform:Matrix = new Matrix();
			debugStencil.matrixCenterRotateInplace(pos.x, pos.y, 0, transform);
			terrain.subtractStencil(debugStencil, transform);
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