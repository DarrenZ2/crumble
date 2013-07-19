package
{
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Polygon;
	
	import starling.display.Quad;

	public final class DebugBoxClass
	{
		private const w:Number = 15;
		private const h:Number = 15;
		private var bodyVerts:Array;
		private var material:Material;
		
		public function DebugBoxClass()
		{
			bodyVerts = Polygon.box(w, h);
			material = new Material(1.2);
		}
			
		public function spawn(pos:Vec2):void
		{
			var visual:Quad = new Quad(w, h);
			visual.pivotX = w/2;
			visual.pivotY = h/2;
			visual.color = 0xffff00ff;
			
			var body:Body = new Body(BodyType.DYNAMIC);
			body.shapes.add(new Polygon(bodyVerts));
			body.setShapeMaterials(material);
			body.position.setxy(pos.x, pos.y); 
			body.userData.graphic = visual;

			Game.service.display.addChild(visual);
			Game.service.space.bodies.add(body);
		}
	}
}