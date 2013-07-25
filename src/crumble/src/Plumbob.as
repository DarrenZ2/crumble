package
{
	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	
	import nape.geom.Vec2;
	
	import starling.display.Sprite;
	import starling.events.ResizeEvent;
	import starling.utils.deg2rad;

	public final class Plumbob extends Sprite
	{
		private var accelerometer:Accelerometer;
		private var border1:DisplayPolygon;
		private var border2:DisplayPolygon;
		private var border3:DisplayPolygon;
		private var border4:DisplayPolygon;
		private const indicatorRadius:Number = 300;
		private const zeroBias:Number = deg2rad(90);
		private const maxAngle:Number = deg2rad(100);
		private const minAngle:Number = deg2rad(-100);
		private const angleSnap:Number = deg2rad(10);
		private var _currentAngle:Number = 0;				public function get currentAngle():Number { return _currentAngle; }
		
		public function start(): void
		{
			visible = true;
		}
		
		public function stop() : void
		{
			visible = false;
			_currentAngle = 0;
		}

		public function Plumbob()
		{
			accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE, onAccelerometerUpdate);
			
			// length of border triangles indicate rotational acceleration
			var color:uint = 0xFF4080FF
				
			border1 = new DisplayPolygon(30, 3, color);
			border2 = new DisplayPolygon(30, 3, color);
			border3 = new DisplayPolygon(30, 3, color);
			border4 = new DisplayPolygon(30, 3, color);

			// pivot approximately around base of triangle
			border1.pivotX =
			border2.pivotX =
			border3.pivotX =
			border4.pivotX = -15;
			
			// circumscribe the radius
			border1.rotation = 0;
			border3.rotation = deg2rad(90);
			border2.rotation = deg2rad(180);
			border4.rotation = deg2rad(270);
			
			var r:Number = indicatorRadius;
			
			border1.x = 0;
			border1.y = -r;
			border2.x = 0;
			border2.y = r;
			border3.x = r;
			border3.y = 0;
			border4.x = -r;
			border4.y = 0;
			
			// thickness scale
			border1.scaleY = 
			border2.scaleY = 
			border3.scaleY = 
			border4.scaleY = 0.4;
			
			// lengthwise scale
			border1.scaleX = 
			border2.scaleX = 
			border3.scaleX = 
			border4.scaleX = 0; // not visible initially
			
			// display the widgets
			addChild(border1);
			addChild(border2);
			addChild(border3);
			addChild(border4);

			this.touchable = false;
			this.visible = false;
			
			Game.service.hud.addChild(this);
			stage.addEventListener(ResizeEvent.RESIZE, onStageResize);
		}
		
		private function onStageResize(event:ResizeEvent):void
		{
			x = event.width / 2;
			y = event.height / 2;
		}
		
		private function onAccelerometerUpdate(event:AccelerometerEvent):void
		{
			if (visible) 
			{
				var v:Vec2 = new Vec2(-event.accelerationX, event.accelerationY);
				
				if (v.length >= 0.5) {
					const twopi:Number = 2*Math.PI;
					var rot:Number = (twopi + v.angle + zeroBias) % twopi - Math.PI; // zeroBias moves the 0 point to the 'bottom' and the -+pi singularity to the 'top'
					rot = (Math.floor((rot + twopi) / angleSnap + 0.5) * angleSnap) - twopi;
					
					if (rot < minAngle || rot > maxAngle) {
						_currentAngle = 0; // player tilted too far
					}
					else {
						_currentAngle = rot;
					}
				}
				else {
					_currentAngle = 0; // player has the phone lying flat
					// TODO: read from z-axis instead?
				}
	
				// adjust all lengthwise scales accordingly- longer = more acceleration
				border1.scaleX = 
				border2.scaleX = 
				border3.scaleX = 
				border4.scaleX = _currentAngle * 4;
			}
		}
	}
}