package
{
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.space.Space;

	public final class PointGravity implements IGravity
	{
		private var _origin:Vec2;
		private var deadRadius:Number;
		private var _radiusAmount:Number;
		private var _tangentAmount:Number;
		private var space:Space;
		
		public function PointGravity(space:Space, origin:Vec2, radiusAmount:Number)
		{
			this.space = space;
			this._origin = origin;
			this.deadRadius = 1;
			this._radiusAmount = radiusAmount;
			this._tangentAmount = 0;
		}
		
		public function get radiusAmount():Number { return _radiusAmount; }
		public function set radiusAmount(value:Number):void { _radiusAmount = value; }
		public function get tangentAmount():Number { return _tangentAmount; }
		public function set tangentAmount(value:Number):void { _tangentAmount = value; }
		public function get origin():Vec2 { return _origin; }
		public function set origin(origin:Vec2):void { _origin = origin; }
		
		public function preFrameUpdate(deltaTime:Number):void 
		{
			space.liveBodies.foreach(function(b:Body):void {
				var gravity:Vec2 = origin.sub(b.position);
				if (gravity.length >= deadRadius) {
					// Radial acceleration in/out
					gravity.length = radiusAmount;
					b.velocity = b.velocity.addMul(gravity, deltaTime);
					
					// Tangential acceleration cw/ccw
					var tangrav:Vec2 = new Vec2(-gravity.y, gravity.x);
					tangrav.length = tangentAmount;
					b.velocity = b.velocity.addMul(tangrav, deltaTime);
				}
			});
		}
	}
}