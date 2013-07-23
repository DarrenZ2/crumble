package
{
	import flash.geom.Matrix;
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
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.PDParticleSystem;
		
	public final class Game extends Sprite implements IGameService
	{
		private static const spaceDebugOverlay:Boolean = false;

		private static var _service:IGameService;		public static function get service():IGameService { return _service; }
		private var _background:Background;				public function get background():DisplayObjectContainer { return _background; }
		private var _foreground:Sprite;					public function get foreground():DisplayObjectContainer { return _foreground; }
		private var gravity:IGravity;
		private var border:Body;
		private var _space:Space;						public function get space():Space { return _space; }
		private var debug:Debug;
		private var bodyQueryCache:BodyList;
		private var _terrain:Terrain;					public function get terrain():Terrain { return _terrain; }
		private var _classes:GameClasses;				public function get classes():GameClasses { return _classes; }
		private var _shared:SharedResources;			public function get shared():SharedResources { return _shared; }
		private const terrainWidth:int = 1024;
		private const terrainHeight:int = 1024;
		private const initialCircleRadius:Number = 128;
		private const pointGravityMagnitude:Number = -400;
		private const minScale:Number = 0.5;
		private const maxScale:Number = 1.5;

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
		
		private static function createQuadRect(x:Number, y:Number, w:Number, h:Number):Quad
		{
			var q:Quad = new Quad(w, h);
			q.x = x;
			q.y = y;
			q.color = 0xFF181818;
			return q;
			
		}
		private function createBorderBody(bounds:Rectangle):Body
		{
			var t:Number = 9000; // thickness- large number to make ground look like it goes on forever
			
			var x1:Number = bounds.x;
			var y1:Number = bounds.y;
			var x2:Number = bounds.right;
			var y2:Number = bounds.bottom;
			
			var b:Body = new Body(BodyType.STATIC);
			
			b.setShapeMaterials(_shared.cordonMaterial);

			b.shapes.add(new Polygon(Polygon.rect(x1-t, y2  , x2+t+t, y1+t)));
			b.shapes.add(new Polygon(Polygon.rect(x1-t, y1-t, x2+t+t, y1+t)));
			b.shapes.add(new Polygon(Polygon.rect(x2  , y1  , x1+t  , y2  )));
			b.shapes.add(new Polygon(Polygon.rect(x1-t, y1  , x1+t  , y2  )));

			var visual:Sprite = new Sprite();
			visual.addChild(createQuadRect(x1-t, y2  , x2+t+t, y1+t));
			visual.addChild(createQuadRect(x1-t, y1-t, x2+t+t, y1+t));
			visual.addChild(createQuadRect(x2  , y1  , x1+t  , y2  ));
			visual.addChild(createQuadRect(x1-t, y1  , x1+t  , y2  ));
			
			b.userData.visual = visual;
			
			return b;
		}
		
		private function initialize(event:Event):void
		{
			if (event != null) {
				removeEventListener(Event.ADDED_TO_STAGE, initialize);
			}

			_service = this as IGameService;
			
			_background = new Background();
			addChild(background);

			_foreground = new Sprite();
			addChild(foreground);

			_space = new Space(Vec2.weak(0, 0));
			_classes = new GameClasses(); // there are some hidden dependencies on _space at the moment (see MortarClass ctor)
			_shared = new SharedResources();

			// gravity
			gravity = new PointGravity(space, new Vec2(terrainWidth/2, terrainHeight/2), pointGravityMagnitude);
			//gravity = new AccelerometerGravity(_space);

			if (spaceDebugOverlay) {
				debug = new BitmapDebug(terrainWidth, terrainHeight, stage.color);
				Starling.current.nativeOverlay.addChild(debug.display);
			}

			// border prevents objects from leaving the stage
			border = createBorderBody(new Rectangle(0, 0, terrainWidth, terrainHeight));
			border.space = space;
			foreground.addChild(border.userData.visual);

			// terrain - start with a hole punched in the center
			_terrain = new Terrain(_space, terrainWidth, terrainHeight);
			_foreground.addChild(_terrain);
			var circleTransform:Matrix = new Matrix();
			_shared.circleStencil512.matrixScaleRotateCenterInplace(initialCircleRadius/512, initialCircleRadius/512, 0, terrainWidth/2, terrainHeight/2, circleTransform);
			_terrain.subtractStencil(_shared.circleStencil512, circleTransform);
			
			// continuous events
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			
			stage.addEventListener(ResizeEvent.RESIZE, onStageResize);
			resize(stage.stageWidth, stage.stageHeight); // prime the sizes
			
			// add three tanks
			_classes.tank.spawn(2*Math.PI*0/3, 0xFFFF0000);
			_classes.tank.spawn(2*Math.PI*1/3, 0xFFFFFF00);
			_classes.tank.spawn(2*Math.PI*2/3, 0xFF0000FF);
		}

		// Scale value to fit the foreground dimension (f) to the stage dimension (s).
		private function fitScale(s:Number, f:Number):Number
		{
			return s/f;
		}
		
		private function resize(w:Number, h:Number):void
		{
			// Foreground is centered according to terrain dimensions.
			// TODO: Fit to screen, and possibly enable pinch/spread/pan.
			var insetScale:Number = 0.85;	// so that the radius is not up against the edge of the screen
			var fgs:Number = Math.min(Math.min(fitScale(w, 2*initialCircleRadius), fitScale(h, 2*initialCircleRadius)) * insetScale, maxScale);
			var fgx:Number = (w - terrainWidth * fgs) / 2; // centered! ooohhhhhmmmmmmm..
			var fgy:Number = (h - terrainHeight * fgs) / 2;
			var fgw:Number = terrainWidth;
			var fgh:Number = terrainHeight;
			
			// Debug exists in the foreground, but must be handled separately
			// because it uses a flash DisplayObject instead of a Starling
			// DisplayObject.
			if (debug != null) {
				debug.display.x = fgx;
				debug.display.y = fgy;
				debug.display.width = fgw;
				debug.display.height = fgh;
				debug.display.scaleX = fgs;
				debug.display.scaleY = fgs;
			}
			
			_foreground.x = fgx;
			_foreground.y = fgy;
			_foreground.width = fgw;
			_foreground.height = fgh;
			_foreground.scaleX = fgs;
			_foreground.scaleY = fgs;

			// Background remains fullscreen unscaled and untranslated.
			_background.x = x;
			_background.y = y;
			_background.width = w;
			_background.height = h;
			_background.scaleX = 1;
			_background.scaleY = 1;
		}

		private function onStageResize(event:ResizeEvent):void
		{
			resize(event.width, event.height);
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
			var endTouches:Vector.<Touch> = event.getTouches(_foreground, TouchPhase.ENDED);
			for each (var touch:Touch in endTouches)
			{
				var pos:Point = touch.getLocation(_foreground);
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
			
			var moveTouches:Vector.<Touch> = event.getTouches(_foreground, TouchPhase.MOVED);
			if (moveTouches.length == 1) {
			}
			else if (moveTouches.length == 2) {
				// two fingers touching -> rotate and scale
				var touchA:Touch = moveTouches[0];
				var touchB:Touch = moveTouches[1];
				
				var currentPosA:Point  = touchA.getLocation(parent);
				var previousPosA:Point = touchA.getPreviousLocation(parent);
				var currentPosB:Point  = touchB.getLocation(parent);
				var previousPosB:Point = touchB.getPreviousLocation(parent);
				
				var currentVector:Point  = currentPosA.subtract(currentPosB);
				var previousVector:Point = previousPosA.subtract(previousPosB);
				
				var currentAngle:Number  = Math.atan2(currentVector.y, currentVector.x);
				var previousAngle:Number = Math.atan2(previousVector.y, previousVector.x);
				var deltaAngle:Number = currentAngle - previousAngle;
				
				// update pivot point based on previous center
				var previousLocalA:Point  = touchA.getPreviousLocation(_foreground);
				var previousLocalB:Point  = touchB.getPreviousLocation(_foreground);
				_foreground.pivotX = (previousLocalA.x + previousLocalB.x) * 0.5;
				_foreground.pivotY = (previousLocalA.y + previousLocalB.y) * 0.5;
				
				// update location based on the current center
				_foreground.x = (currentPosA.x + currentPosB.x) * 0.5;
				_foreground.y = (currentPosA.y + currentPosB.y) * 0.5;
				
				// rotate
				//_foreground.rotation += deltaAngle;
				
				// scale
				var sizeDiff:Number = currentVector.length / previousVector.length;
				_foreground.scaleX *= sizeDiff;
				_foreground.scaleY *= sizeDiff;
				
				_foreground.scaleX = Math.max(Math.min(_foreground.scaleX, maxScale), minScale);
				_foreground.scaleY = Math.max(Math.min(_foreground.scaleY, maxScale), minScale);
			}
		}
	}
}