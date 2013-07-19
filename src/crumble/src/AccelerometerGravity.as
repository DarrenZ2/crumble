package
{
	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	
	import nape.geom.Vec2;
	import nape.space.Space;

	public final class AccelerometerGravity implements IGravity
	{
		private var accelerometer:Accelerometer;
		private var space:Space;

		public function AccelerometerGravity(space:Space)
		{
			this.space = space;
			accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE, onAccelerometerUpdate);
		}
		
		public static function get isSupported():Boolean
		{
			return Accelerometer.isSupported;	
		}
		
		private function onAccelerometerUpdate(event:AccelerometerEvent):void
		{
			const accmul:Number = 6000;
			space.gravity = Vec2.weak(-accmul * event.accelerationX, accmul * event.accelerationY);
		}
		
		public function preFrameUpdate(deltaTime:Number):void
		{
			// does nothing
		}
	}
}