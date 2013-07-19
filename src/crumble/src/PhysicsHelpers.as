package
{
	import nape.geom.Vec2;

	public final class PhysicsHelpers
	{
		public static function directionFromAngle(angle:Number):Vec2
		{
			return new Vec2(Math.cos(angle), Math.sin(angle));
		}
	}
}