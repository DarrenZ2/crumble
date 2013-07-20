package
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	import nape.util.BitmapDebug;
	import nape.util.Debug;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.PDParticleSystem;
		
	public final class Game extends Sprite implements IGameService
	{
		private static const spaceDebugOverlay:Boolean = false;

		private static var _service:IGameService;		public static function get service():IGameService { return _service; }
		private var background:Background;
		private var gravity:IGravity;
		private var border:Body;
		private var _space:Space;						public function get space():Space { return _space; }
		private var debug:Debug;
		private var bodyQueryCache:BodyList;
		private var _terrain:Terrain;					public function get terrain():Terrain { return _terrain; }
		private var _classes:GameClasses;				public function get classes():GameClasses { return _classes; }
														public function get display():DisplayObjectContainer { return this as DisplayObjectContainer; }		
		
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
		
		private function createBorderBody(bounds:Rectangle):Body
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
			
			b.cbTypes.add(CallbackTypes.TERRAIN); // this causes terrain callback to trigger mortar explosion

			return b;
		}
		
		private function initialize(event:Event):void
		{
			if (event != null) {
				removeEventListener(Event.ADDED_TO_STAGE, initialize);
			}

			_service = this as IGameService;
			
			var background:Background = new Background();
			addChild(background);
			
			_space = new Space(Vec2.weak(0, 600));
			_classes = new GameClasses(); // there are some hidden dependencies on _space at the moment (see MortarClass ctor)

			// gravity
			gravity = new PointGravity(space, new Vec2(stage.stageWidth/2, stage.stageHeight/2));
			//gravity = new AccelerometerGravity(_space);

			if (spaceDebugOverlay) {
				debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, stage.color);
				Starling.current.nativeOverlay.addChild(debug.display);
			}

			// border prevents objects from leaving the stage
			border = createBorderBody(stage.bounds);
			border.space = space;

			// terrain
			_terrain = new Terrain(_space);
			addChild(_terrain);
			
			// continuous events
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onEnterFrame(event:EnterFrameEvent):void
		{
			var dt:Number = 1 / Crumble.frameRate;
			
			if (gravity != null) {
				gravity.preFrameUpdate(dt);
			}
			
			_space.step(dt);
			
			_space.liveBodies.foreach(function(b:Body):void {
				var visual:DisplayObject = b.userData.visual;
				if (visual != null) {
					visual.x = b.position.x; 
					visual.y = b.position.y;
					visual.rotation = b.rotation;
				}
				
				var ps:PDParticleSystem = b.userData.particleSystem;
				if (ps != null) {
					ps.emitterX = b.position.x;
					ps.emitterY = b.position.y;
				}
			});
			
			if (spaceDebugOverlay) {
				debug.clear();
				debug.draw(_space);
				debug.flush();
			}
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.BEGAN);
			for each (var touch:Touch in touches)
			{
				var pos:Point = touch.getLocation(this);
				bodyQueryCache.clear();
				_space.bodiesUnderPoint(Vec2.fromPoint(pos, true),  null, bodyQueryCache);
				
				var hitTerrain:Boolean = false;
				for (var i:int = 0; i < bodyQueryCache.length && !hitTerrain; i++) {
					if (bodyQueryCache.at(i).isStatic()) {
						hitTerrain = true;
					}
				}
				
				if (hitTerrain) {
					// do nothing
				}
				else {
					// weapon test
					_classes.mortar.spawn(new Vec2(pos.x, pos.y), Math.PI*Math.random()*2);
				}
			}
		}
	}
}