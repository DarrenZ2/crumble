package
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public final class RectangleHelpers
	{
		public static function extendRectangleBoundsInplace(p:Point, result:Rectangle):void
		{
			var x1:Number = result.left;
			var x2:Number = result.right;
			var y1:Number = result.top;
			var y2:Number = result.bottom;
			
			if (p.x < x1) {
				x1 = p.x;
			}
			if (p.x > x2) {
				x2 = p.x;
			}
			if (p.y < y1) {
				y1 = p.y;
			}
			if (p.y > y2) {
				y2 = p.y;
			}
			
			result.left = x1;
			result.right = x2;
			result.top = y1;
			result.bottom = y2;
		}
		
		public static function boundsFromTransformedRect(rect:Rectangle, transform:Matrix):Rectangle
		{
			const p1:Point = transform.transformPoint(new Point(rect.left, rect.top));
			const p2:Point = transform.transformPoint(new Point(rect.right, rect.top));
			const p3:Point = transform.transformPoint(new Point(rect.left, rect.bottom));
			const p4:Point = transform.transformPoint(new Point(rect.right, rect.bottom));
			
			var result:Rectangle = new Rectangle(p1.x, p1.y);
			extendRectangleBoundsInplace(p2, result);
			extendRectangleBoundsInplace(p3, result);
			extendRectangleBoundsInplace(p4, result);
			
			return result;
		}	
	}
}