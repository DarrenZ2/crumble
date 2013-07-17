package
{
	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	
	import nape.geom.Vec2;
	import nape.space.Space;

	public final class AccelerometerGravity
	{
		private var accelerometer:Accelerometer;
		private var _space:Space;
		
		public static function get isSupported():Boolean
		{
			return Accelerometer.isSupported;	
		}
		
		public function set space(space:Space):void
		{
			_space = space;
		}
		
		public function get space():Space
		{
			return _space;
		}
		
		private function onAccelerometerUpdate(event:AccelerometerEvent):void
		{
			const accmul:Number = 6000;
			space.gravity = Vec2.weak(-accmul * event.accelerationX, accmul * event.accelerationY);
		}

		public function AccelerometerGravity()
		{
			accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE, onAccelerometerUpdate);
		}
	}
}