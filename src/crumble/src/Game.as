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
	import nape.util.Debug;
	import nape.util.ShapeDebug;
	
	import starling.animation.IAnimatable;
	import starling.animation.Juggler;
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
		
	public final class Game extends Sprite implements IGameService, IAnimatable
	{
		private static const spaceDebugOverlay:Boolean = false;

		private static var _service:IGameService;		public static function get service():IGameService { return _service; }
		private var _simulator:Juggler;					public function get simulator():Juggler { return _simulator; }
		private var _background:Background;				public function get background():DisplayObjectContainer { return _background; }
		private var _foreground:Sprite;					public function get foreground():DisplayObjectContainer { return _foreground; }
		private var _hud:Sprite;						public function get hud():DisplayObjectContainer { return _hud; }
		private var gravity:PointGravity;
		private var border:Body;
		private var _space:Space;						public function get space():Space { return _space; }
		private var spaceActive:Boolean = true;
		private var debug:Debug;
		private var bodyQueryCache:BodyList;
		private var _terrain:Terrain;					public function get terrain():Terrain { return _terrain; }
		private var _classes:GameClasses;				public function get classes():GameClasses { return _classes; }
		private var _shared:SharedResources;			public function get shared():SharedResources { return _shared; }
		private var _windWidget:WindWidget;				public function get windWidget():WindWidget { return _windWidget; }
		private var _planter:Planter;					public function get planter():Planter { return _planter; }
		private var _tanks:Vector.<Body>;				public function get tanks():Vector.<Body> { return _tanks; }
		private var _currentPlayerIndex:int = 0;		public function get currentPlayerIndex():int { return _currentPlayerIndex; }		public function set currentPlayerIndex(value:int):void { _currentPlayerIndex = value; }
		private const terrainWidth:int = 1024;
		private const terrainHeight:int = 1024;
		public static const initialCircleRadius:Number = 278;
		private const pointGravityMagnitude:Number = -400;
		private const minScale:Number = 0.5;
		private const maxScale:Number = 4.0;

		public function pausePhysics():void
		{
			spaceActive = false;
		}
		
		public function resumePhysics():void
		{
			spaceActive = true;
		}
		
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
			var ct:Number = 16; 	// collision thickness- large enough to prevent leaks, though I find nape's CCD to be sufficient even for thin bits
			var vt:Number = 8192; 	// visual thickness- large number to make ground look like it goes on forever
			
			var x1:Number = bounds.x;
			var y1:Number = bounds.y;
			var x2:Number = bounds.right;
			var y2:Number = bounds.bottom;
			
			var b:Body = new Body(BodyType.STATIC);
			
			b.setShapeMaterials(_shared.cordonMaterial);

			b.shapes.add(new Polygon(Polygon.rect(x1-ct, y2   , x2+ct+ct, y1+ct)));
			b.shapes.add(new Polygon(Polygon.rect(x1-ct, y1-ct, x2+ct+ct, y1+ct)));
			b.shapes.add(new Polygon(Polygon.rect(x2   , y1   , x1+ct   , y2   )));
			b.shapes.add(new Polygon(Polygon.rect(x1-ct, y1   , x1+ct   , y2   )));

			var visual:Sprite = new Sprite();
			visual.addChild(createQuadRect(x1-vt, y2   , x2+vt+vt, y1+vt));
			visual.addChild(createQuadRect(x1-vt, y1-vt, x2+vt+vt, y1+vt));
			visual.addChild(createQuadRect(x2   , y1   , x1+vt   , y2   ));
			visual.addChild(createQuadRect(x1-vt, y1   , x1+vt   , y2   ));
			
			b.userData.visual = visual;
			
			return b;
		}
		
		private function initialize(event:Event):void
		{
			if (event != null) {
				removeEventListener(Event.ADDED_TO_STAGE, initialize);
			}

			_service = this as IGameService;
			_simulator = new Juggler();
			_simulator.add(this);
			
			_background = new Background(Math.max(terrainWidth, terrainHeight));
			addChild(background);

			_foreground = new Sprite();
			addChild(foreground);

			_hud = new Sprite();
			addChild(_hud);
			
			_space = new Space(Vec2.weak(0, 0));
			_classes = new GameClasses(); // there are some hidden dependencies on _space at the moment (see MortarClass ctor)
			_shared = new SharedResources();

			// gravity
			gravity = new PointGravity(space, new Vec2(terrainWidth/2, terrainHeight/2), pointGravityMagnitude);
			//gravity = new AccelerometerGravity(_space);

			if (spaceDebugOverlay) {
				debug = new ShapeDebug(terrainWidth, terrainHeight, stage.color);
				Starling.current.nativeOverlay.addChild(debug.display);
			}

			// border prevents objects from leaving the stage
			border = createBorderBody(new Rectangle(0, 0, terrainWidth, terrainHeight));
			border.space = space;
			foreground.addChild(border.userData.visual);

			// new filled terrain
			_terrain = new Terrain(_space, terrainWidth, terrainHeight);
			_foreground.addChild(_terrain);
			
			// add widgets etc
			_windWidget = new WindWidget();
			_planter = new Planter();
			_tanks = new Vector.<Body>();
			
			// events and layout
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			stage.addEventListener(ResizeEvent.RESIZE, onStageResize);
			resize(stage.stageWidth, stage.stageHeight); // prime the sizes
			
			PliskenMode.run();
		}

		// Scale value to fit the foreground dimension (f) to the stage dimension (s).
		private function fitScale(s:Number, f:Number):Number
		{
			return s/f;
		}
		
		private function resize(w:Number, h:Number):void
		{
			// Foreground is centered according to terrain dimensions.
			// TODO: Fit to screen.
			var insetScale:Number = 0.85;	// so that the radius is not up against the edge of the screen
			var fgs:Number = Math.min(Math.min(fitScale(w, 2*initialCircleRadius), fitScale(h, 2*initialCircleRadius)) * insetScale, maxScale);
			var fgx:Number = w/2; // centered! ooohhhhhmmmmmmm..
			var fgy:Number = h/2;
			var fgw:Number = terrainWidth;
			var fgh:Number = terrainHeight;
			var cx:Number = terrainWidth/2;
			var cy:Number = terrainHeight/2;
			
			_foreground.x = fgx;
			_foreground.y = fgy;
			_foreground.width = fgw;
			_foreground.height = fgh;
			_foreground.scaleX = fgs;
			_foreground.scaleY = fgs;
			_foreground.pivotX = cx;
			_foreground.pivotY = cy;

			_background.x = fgx;
			_background.y = fgy;
			_background.width = fgw;
			_background.height = fgh;
			_background.scaleX = fgs;
			_background.scaleY = fgs;
			_background.pivotX = cx;
			_background.pivotY = cy;
			
			// Hud remains fullscreen and untranslated.
			_hud.x = x;
			_hud.y = y;
			_hud.width = w;
			_hud.height = h;
			_hud.scaleX = 1;
			_hud.scaleY = 1;
			_hud.pivotX = 0;
			_hud.pivotY = 0;
		}

		private function onStageResize(event:ResizeEvent):void
		{
			resize(event.width, event.height);
		}
		
		public function updateBodyVisuals(body:Body):void
		{
			var visual:DisplayObject = body.userData.visual;
			if (visual != null) {
				visual.x = body.position.x; 
				visual.y = body.position.y;
				visual.rotation = body.rotation;
			}
			
			var ps:PDParticleSystem = body.userData.particleSystem;
			if (ps != null) {
				ps.emitterX = body.position.x;
				ps.emitterY = body.position.y;
			}
		}

		public function advanceTime(deltaTime:Number):void
		{
			if (spaceActive) {
				gravity.tangentAmount = _windWidget.currentAngle * 900;
				gravity.preFrameUpdate(deltaTime);
				_space.step(deltaTime);
			}
			
			_space.liveBodies.foreach(function(b:Body):void {
				updateBodyVisuals(b);
			});
			
			if (spaceDebugOverlay) {
				// Debug exists in the foreground, but must be handled separately
				// because it uses a flash DisplayObject instead of a Starling
				// DisplayObject.
				debug.display.transform.matrix = _foreground.transformationMatrix;
				
				debug.clear();
				debug.draw(_space);
				debug.flush();
			}
		}

		private function onEnterFrame(event:EnterFrameEvent):void
		{
			_simulator.advanceTime(1 / Crumble.frameRate);
		}
		
		private function onTouch(event:TouchEvent):void
		{
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
				//_foreground.pivotX = (previousLocalA.x + previousLocalB.x) * 0.5;
				//_foreground.pivotY = (previousLocalA.y + previousLocalB.y) * 0.5;
				
				// update location based on the current center
				//_foreground.x = (currentPosA.x + currentPosB.x) * 0.5;
				//_foreground.y = (currentPosA.y + currentPosB.y) * 0.5;
				
				// rotate
				//_foreground.rotation += deltaAngle;
				
				// scale
				var sizeDiff:Number = currentVector.length / previousVector.length;
				_foreground.scaleX *= sizeDiff;
				_foreground.scaleY *= sizeDiff;
				
				_foreground.scaleX = Math.max(Math.min(_foreground.scaleX, maxScale), minScale);
				_foreground.scaleY = Math.max(Math.min(_foreground.scaleY, maxScale), minScale);
				_background.scaleX = _foreground.scaleX;
				_background.scaleY = _foreground.scaleY;
			}
		}
	}
}