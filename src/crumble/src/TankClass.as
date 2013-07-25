package
{
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Polygon;
	
	import starling.display.Quad;

	public final class TankClass
	{
		private const radius:Number = 20;
		private var bodyVerts:Array;
		private var material:Material;
		
		public function TankClass()
		{
			bodyVerts = Polygon.regular(radius, radius, 3, 0);
			material = new Material(1.2);
		}
		
		public function spawn(rot:Number, color:uint):Body
		{
			var dir:Vec2 = PhysicsHelpers.directionFromAngle(rot);

			var r:Number = radius * 0.667;
			var visual:Quad = new starling.display.Quad(r*2, r*2, color);
			visual.pivotX = r;
			visual.pivotY = r;
//			var visual:DisplayPolygon = new DisplayPolygon(radius, 3, color);
			
			var body:Body = new Body(BodyType.DYNAMIC);
			body.cbTypes.add(CallbackTypes.TANK);
			body.shapes.add(new Polygon(bodyVerts));
			body.setShapeMaterials(Game.service.shared.tankMaterial);
			body.position = new Vec2(Game.service.terrain.terrainWidth /2 + dir.x * radius * 2,
									 Game.service.terrain.terrainHeight/2 + dir.y * radius * 2);
			body.rotation = rot + Math.PI;
			body.userData.visual = visual;
			body.userData.health = 100.0;

			Game.service.foreground.addChild(visual);
			Game.service.space.bodies.add(body);
			
			return body;
		}
	}
}