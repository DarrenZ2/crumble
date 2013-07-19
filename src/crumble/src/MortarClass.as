package
{
	import flash.geom.Matrix;
	
	import nape.callbacks.CbEvent;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.geom.Geom;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	
	import starling.display.Quad;
	import starling.display.Sprite;

	public final class MortarClass extends Sprite
	{
		private const w:Number = 15;
		private const h:Number = 15;
		private const explosionRadius:Number = 50;
		private var distSamplePoint:Body;
		private var bodyVerts:Array;
		private var explosionStencil:Stencil;
		
		public function MortarClass()
		{
			bodyVerts = Polygon.box(w, h);
			explosionStencil = Stencil.createDebugCircle(explosionRadius); // TODO: Replace with assets
			distSamplePoint = new Body();
			distSamplePoint.shapes.add(new Circle(0.001));
		}
		
		private function subtractExplosionStencilAt(pos:Vec2):void
		{
			var transform:Matrix = new Matrix();
			explosionStencil.matrixCenterRotateInplace(pos.x, pos.y, 0, transform);
			Game.service.terrain.subtractStencil(explosionStencil, transform);
		}
		
		private function applyRadialImpulseAt(pos:Vec2):void
		{
			distSamplePoint.position = pos;
			var closest1:Vec2 = Vec2.get();
			var closest2:Vec2 = Vec2.get();

			var bs:BodyList = Game.service.space.bodiesInCircle(pos, explosionRadius+500, false);
			for (var i:int = 0; i < bs.length; i++) {
				var b:Body = bs.at(i);
				
				if (!b.isDynamic()) {
					continue;
				}
					
				// find closest point on body
				var distance:Number = Geom.distanceBody(distSamplePoint, b, closest1, closest2);
				
				// apply impulse
				var impulse:Vec2 = closest2.sub(pos);
				impulse.length = 10;
				b.applyImpulse(impulse, null, true);
			}
		}
		
		private function terrainCollision(cb:InteractionCallback):void
		{
			var b:Body = cb.int2.castBody;
			
			subtractExplosionStencilAt(b.worldCOM);
			applyRadialImpulseAt(b.worldCOM);
			
			// clean up the visual and physical objects
			Game.service.display.removeChild(b.userData.visual, true);
			Game.service.space.bodies.remove(b);
		}
		
		public function spawn(pos:Vec2, rot:Number):void
		{
			var visual:Quad = new Quad(w, h);
			visual.pivotX = w/2;
			visual.pivotY = h/2;
			visual.color = 0xff00ffff;
			
			var body:Body = new Body(BodyType.DYNAMIC);
			body.shapes.add(new Polygon(bodyVerts));
			body.position = pos; 
			body.rotation = rot;
			body.velocity = PhysicsHelpers.directionFromAngle(rot);
			body.velocity.length = 100;
			body.userData.visual = visual;
			body.cbTypes.add(Game.service.classes.physMissileType);

			Game.service.display.addChild(visual);
			Game.service.space.bodies.add(body);
			Game.service.space.listeners.add(new InteractionListener(
				CbEvent.BEGIN, 
				InteractionType.COLLISION, 
				Game.service.classes.physTerrainType, 
				Game.service.classes.physMissileType, 
				terrainCollision
			));
		}
	}
}
