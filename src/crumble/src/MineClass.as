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
	
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;

	public final class MineClass
	{
		[Embed(source="explosion.pex", mimeType="application/octet-stream")]
		private static const ExplosionConfig:Class;
		private const explosionEmitterDuration:Number = 0.2;
		private const explosionTimeout:Number = 0.5;
		private const explosionConfig:XML = XML(new ExplosionConfig());
		
		[Embed(source = "blob.png")]
		private static const BlobBitmap:Class;
		private const blobTexture:Texture = Texture.fromBitmap(new BlobBitmap());
		
		private const collisionRadius:Number = 8;
		private const explosionRadius:Number = 64;
		private var distSamplePoint:Body;
		
		public function MineClass()
		{
			// point-approximation hack for closest point checks
			distSamplePoint = new Body();
			distSamplePoint.shapes.add(new Circle(0.001));
			
			Game.service.space.listeners.add(new InteractionListener(
				CbEvent.BEGIN, 
				InteractionType.COLLISION, 
				CallbackTypes.TANK, 
				CallbackTypes.MINE, 
				tankCollision
			));
		}
		
		private function subtractExplosionStencilAt(pos:Vec2):void
		{
			var transform:Matrix = new Matrix();
			Game.service.shared.circleStencil512.matrixScaleRotateCenterInplace(explosionRadius/512, explosionRadius/512, 0, pos.x, pos.y, transform);
			Game.service.terrain.subtractStencil(Game.service.shared.circleStencil512, transform);
		}
		
		private function applyRadialImpulseAt(pos:Vec2):void
		{
			distSamplePoint.position = pos;
			var closest1:Vec2 = Vec2.get();
			var closest2:Vec2 = Vec2.get();
			
			var bs:BodyList = Game.service.space.bodiesInCircle(pos, explosionRadius, false);
			for (var i:int = 0; i < bs.length; i++) {
				var b:Body = bs.at(i);
				
				if (!b.isDynamic()) {
					continue;
				}
				
				// find closest point on body
				var distance:Number = Geom.distanceBody(distSamplePoint, b, closest1, closest2);
				
				// apply impulse
				var impulse:Vec2 = closest2.sub(pos);
				impulse.length = 320;
				b.applyImpulse(impulse, null, true);
				
				// subtract health
				if (b.userData.health != null) {
					b.userData.health -= 25;
					if (b.userData.health < 0) {
						b.userData.health = 0;
					}
				}
			}
		}
		
		private function removeParticleSystem(ps:PDParticleSystem):void
		{
			Game.service.simulator.remove(ps);
			Game.service.foreground.removeChild(ps, true);
		}
		
		private function tankCollision(cb:InteractionCallback):void
		{
			var b:Body = cb.int2.castBody;
			explode(cb.int2.castBody);
		}
		
		private function explode(body:Body):void
		{
			subtractExplosionStencilAt(body.worldCOM);
			applyRadialImpulseAt(body.worldCOM);
			
			// cover things up with an explosion effect
			var explosion:PDParticleSystem = new PDParticleSystem(explosionConfig, blobTexture);
			explosion.emitterX = body.worldCOM.x;
			explosion.emitterY = body.worldCOM.y;
			explosion.start(explosionEmitterDuration);
			Game.service.simulator.add(explosion);
			Game.service.simulator.delayCall(removeParticleSystem, explosionTimeout, explosion);
			
			cleanup(body);
			Game.service.foreground.addChild(explosion);
		}
		
		private function cleanup(body:Body):void
		{
			// clean up the visual and physical objects
			Game.service.foreground.removeChild(body.userData.visual, true);
			Game.service.space.bodies.remove(body);
		}
		
		public function spawn(pos:Vec2, rot:Number):void
		{
			var body:Body = new Body(BodyType.STATIC);
			body.shapes.add(new Circle(collisionRadius));
			body.setShapeMaterials(Game.service.shared.mineMaterial);
			body.position = pos; 
			body.rotation = rot;
			body.cbTypes.add(CallbackTypes.MINE);
			
			var visual:Quad = new starling.display.Quad(collisionRadius*2, collisionRadius*2, 0xFFFF00FF);
			visual.pivotX = collisionRadius;
			visual.pivotY = collisionRadius;
			body.userData.visual = visual;
			
			Game.service.foreground.addChild(visual);
			Game.service.space.bodies.add(body);
			Game.service.updateBodyVisuals(body);
		}
	}
}