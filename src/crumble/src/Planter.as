package
{
	import flash.geom.Point;
	
	import nape.geom.Vec2;
	
	import starling.display.Sprite;
	import starling.display.BlendMode;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public final class Planter extends Sprite
	{
		private var _touchRadius:Number;
		private var _circlePolygon:DisplayPolygon;
		private var _onPlanted:Function;

		public function Planter()
		{
			super();
			_touchRadius = 130;
			_circlePolygon = new DisplayPolygon(_touchRadius, 64, 0xFF081030);
			_circlePolygon.blendMode = BlendMode.ADD;
			addChild(_circlePolygon);
			addEventListener(TouchEvent.TOUCH, onTouch);
			Game.service.foreground.addChild(this);
			visible = false;
		}
		
		public function start(pos:Vec2, onPlanted:Function):void
		{
			touchable = true;
			visible = true;
			_onPlanted = onPlanted;
		 	this.x = pos.x;
			this.y = pos.y;
		}

		public function cancel():void
		{
			touchable = false;
			visible = false;
			_onPlanted = null;
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var endTouches:Vector.<Touch> = event.getTouches(Game.service.foreground, TouchPhase.ENDED);
			if (endTouches.length == 1) {
				var touch:Touch = endTouches[0];
				var pos:Point = touch.getLocation(Game.service.foreground);

				// plant a mine and kill the planter ui
				Game.service.classes.mine.spawn(new Vec2(pos.x, pos.y), Math.PI*Math.random()*2);
				
				// callback for continuation
				if (_onPlanted != null) {
					_onPlanted();
				}
				
				cancel();
			}
		}		
	}
}