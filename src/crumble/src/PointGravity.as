package
{
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.space.Space;

	public final class PointGravity implements IGravity
	{
		private var _origin:Vec2;
		private var deadRadius:Number;
		private var magnitude:Number;
		private var space:Space;
		
		public function PointGravity(space:Space, origin:Vec2)
		{
			this.space = space;
			this._origin = origin;
			this.deadRadius = 10;
			this.magnitude = 600;
		}
		
		public function get origin():Vec2
		{
			return _origin;
		}
		
		public function set origin(origin:Vec2):void
		{
			_origin = origin;
		}
		
		public function preFrameUpdate(deltaTime:Number):void 
		{
			space.liveBodies.foreach(function(b:Body):void {
				var gravity:Vec2 = origin.sub(b.position);// TODO: new Vec2(stage.stageWidth/2 - b.position.x, stage.stageHeight/2 - b.position.y);
				if (gravity.length >= deadRadius) {
					gravity.length = magnitude;
					b.applyImpulse(gravity.muleq(deltaTime));
				}
			});
		}
	}
}