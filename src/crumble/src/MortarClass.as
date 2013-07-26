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
	
	import starling.display.Sprite;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;

	public final class MortarClass extends Sprite
	{
		[Embed(source="explosion.pex", mimeType="application/octet-stream")]
		private static const ExplosionConfig:Class;
		private const explosionEmitterDuration:Number = 0.2;
		private const explosionTimeout:Number = 0.5;
		private const explosionConfig:XML = XML(new ExplosionConfig());

		[Embed(source="firetrail.pex", mimeType="application/octet-stream")]
		private static const FireTrailConfig:Class;
		private const fireParticleTimeout:Number = 4;
		private const fireTrailConfig:XML = XML(new FireTrailConfig());
		
		[Embed(source = "blob.png")]
		private static const BlobBitmap:Class;
		private const blobTexture:Texture = Texture.fromBitmap(new BlobBitmap());
		
		private const mortarTimeout:Number = 8;
		private const collisionRadius:Number = 2;
		private const explosionRadius:Number = 128;
		private var distSamplePoint:Body;
		
		public function MortarClass()
		{
			// point-approximation hack for closest point checks
			distSamplePoint = new Body();
			distSamplePoint.shapes.add(new Circle(0.001));

			Game.service.space.listeners.add(new InteractionListener(
				CbEvent.BEGIN, 
				InteractionType.COLLISION, 
				CallbackTypes.TERRAIN, 
				CallbackTypes.MISSILE, 
				terrainCollision
			));
		}
		
		private function subtractExplosionStencilAt(pos:Vec2):void
		{
			var transform:Matrix = new Matrix();
			Game.service.shared.circleStencil512.matrixScaleRotateCenterInplace(explosionRadius/512, explosionRadius/512, 0, pos.x, pos.y, transform);
			Game.service.terrain.subtractVisual(Game.service.shared.circleStencil512, transform);
			Game.service.terrain.subtractCollision(Game.service.shared.circleStencil512, transform);
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
				impulse.length = 10;
				b.applyImpulse(impulse, null, true);
			}
		}

		private function removeParticleSystem(ps:PDParticleSystem):void
		{
			Game.service.simulator.remove(ps);
			Game.service.foreground.removeChild(ps, true);
		}
		
		private function terrainCollision(cb:InteractionCallback):void
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
			body.userData.particleSystem.stop();
			Game.service.simulator.remove(body.userData.delayedCall);
			Game.service.simulator.delayCall(removeParticleSystem, fireParticleTimeout, body.userData.particleSystem); // wait until particles expire before removing the system
			Game.service.foreground.removeChild(body.userData.visual, true);
			Game.service.space.bodies.remove(body);
		}
		
		public function spawn(pos:Vec2, rot:Number):void
		{
			var firetrail:PDParticleSystem = new PDParticleSystem(fireTrailConfig, blobTexture);
			Game.service.simulator.add(firetrail);
			firetrail.start();

			var body:Body = new Body(BodyType.DYNAMIC);
			body.shapes.add(new Circle(collisionRadius));
			body.setShapeMaterials(Game.service.shared.mineMaterial);
			body.position = pos; 
			body.rotation = rot;
			body.velocity = PhysicsHelpers.directionFromAngle(rot);
			body.velocity.length = 100;
			body.userData.particleSystem = firetrail;
			body.userData.delayedCall = Game.service.simulator.delayCall(cleanup, this.mortarTimeout, body); 
			body.cbTypes.add(CallbackTypes.MISSILE);

			Game.service.foreground.addChild(firetrail);
			Game.service.space.bodies.add(body);
		}
	}
}
