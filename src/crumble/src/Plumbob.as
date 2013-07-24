package
{
	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	
	import nape.geom.Vec2;
	
	import starling.display.Sprite;
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
		private const maxAngle:Number = deg2rad(40);
		private const minAngle:Number = deg2rad(-40);
		private const angleSnap:Number = deg2rad(5);
		private var _currentAngle:Number = 0;				public function get currentAngle():Number { return _currentAngle; }
		
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
			
			// add them to the display
			addChild(border1);
			addChild(border2);
			addChild(border3);
			addChild(border4);

			this.touchable = false;
		}
		
		private function onAccelerometerUpdate(event:AccelerometerEvent):void
		{
			var v:Vec2 = new Vec2(-event.accelerationX, event.accelerationY);
			
			if (v.length >= 0.5) {
				var rot:Number = v.angle;
				rot = Math.min(rot, maxAngle + zeroBias);
				rot = Math.max(rot, minAngle + zeroBias);
				rot = (Math.floor((rot + deg2rad(360)) / angleSnap + 0.5) * angleSnap) - deg2rad(360);
				
				_currentAngle = rot - zeroBias;
				
				// adjust all lengthwise scales accordingly- longer = more acceleration
				border1.scaleX = 
				border2.scaleX = 
				border3.scaleX = 
				border4.scaleX = _currentAngle * 4;
			}
		}
	}
}