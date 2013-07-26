package
{
	import flash.geom.Matrix;
	
	import nape.geom.Vec2;
	import nape.phys.Body;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.text.TextField;
	import starling.utils.Color;
	
	public final class PliskenMode
	{
		[Embed(source="fg1.png")]
		private static const Foreground:Class;
	
//		[Embed(source="player_blue_01.png")] private static const BluePlayer1:Class;
//		[Embed(source="player_blue_02.png")] private static const BluePlayer2:Class;
//		
//		[Embed(source="player_red_01.png")] private static const RedPlayer1:Class;
//		[Embed(source="player_red_02.png")] private static const RedPlayer2:Class;
//		
//		[Embed(source="player_yellow_01.png")] private static const YellowPlayer1:Class;
//		[Embed(source="player_yellow_02.png")] private static const YellowPlayer2:Class;
		
		public static function run():void
		{
			// set up shared state: terrain, tanks, players, environment
			var circleTransform:Matrix = new Matrix();
			
			Game.service.shared.circleStencil512.matrixScaleRotateCenterInplace(
				Game.initialCircleRadius/512, 
				Game.initialCircleRadius/512, 
				0, 
				Game.service.terrain.terrainWidth/2, 
				Game.service.terrain.terrainHeight/2, 
				circleTransform);
			
			var ident:Matrix = new Matrix();
			ident.identity();
			
			var fgStencil:Stencil = Stencil.createFromBitmap(new Foreground());
			Game.service.terrain.subtractCollision(Game.service.shared.circleStencil512, circleTransform);
			Game.service.terrain.subtractVisual(Game.service.shared.circleStencil512, circleTransform);
			Game.service.terrain.addVisual(fgStencil, ident); 
			fgStencil.dispose();
			
			Game.service.tanks.push(
				Game.service.classes.tank.spawn(2*Math.PI*0/3, 0xFFFF0000, null), //Texture.fromBitmap(new RedPlayer1())),
				Game.service.classes.tank.spawn(2*Math.PI*1/3, 0xFFFFFF00, null), //Texture.fromBitmap(new YellowPlayer1())),
				Game.service.classes.tank.spawn(2*Math.PI*2/3, 0xFF0000FF, null) //Texture.fromBitmap(new BluePlayer1()))
			);
			
			Game.service.currentPlayerIndex = -1; // No valid player initially.
			Game.service.windWidget.stop();

			
			// kick off the game loop
			showTitle("Plisken Mode", 1, 4, Color.WHITE);
			simulationPhase();
		}
		
		private static function showTitle(text:String, delay:Number, duration:Number, color:uint):void
		{
			var title:TextField = new TextField(Game.service.foreground.stage.stageWidth, 256, text, "Title", 64, color);
			title.pivotX = title.width/2;
			title.pivotY = title.height/2;
			title.x = Game.service.foreground.stage.stageWidth/2;
			title.y = Game.service.foreground.stage.stageHeight + title.height;
			
			title.autoScale = true;
			title.filter = Game.service.shared.glowFilter;
			
			Game.service.hud.addChild(title);
			
			Game.service.simulator.delayCall(function():void {
				var titleTween:Tween = new Tween(title, duration, Transitions.EASE_OUT_IN);
				titleTween.animate("y", -title.height);
				Game.service.simulator.add(titleTween);
			}, delay, title);
		}

		private static function simulationPhase():void
		{
			Game.service.resumePhysics();
			Game.service.simulator.delayCall(settlePhase, 3); // let physics simulate with interaction
		}
		
		private static function settlePhase():void
		{
			// Kill velocity on all live bodies and let gravity do the rest
			Game.service.windWidget.stop();
			Game.service.space.liveBodies.foreach(function(b:Body):void {
				b.velocity.x = 0;
				b.velocity.y = 0;
				b.angularVel = 0;
			});
			
			Game.service.simulator.delayCall(plantPhase, 2); // let things settle
		}
		
		private static function plantPhase():void
		{
			Game.service.pausePhysics();

			var delay:Number = 0;
			
			// remove dead tanks
			for (var i:int = 0; i < Game.service.tanks.length;) {
				if (Game.service.tanks[i].userData.health <= 0) {
					showTitle("DEAD", delay, 1, Game.service.tanks[0].userData.visual.color);
					delay += 0.5;
					var oldColor:uint = Game.service.tanks[i].userData.visual.color;
					Game.service.tanks[i].userData.visual.color = 0xFF202020;
					Game.service.tanks.splice(i, 1);
					if (Game.service.currentPlayerIndex >= Game.service.tanks.length) {
						Game.service.currentPlayerIndex = 0;
					}
				}
				else {
					i++;
				}
			}
			
			if (Game.service.tanks.length == 1) {
				// Game over: we have a victor
				showTitle("Victory!", delay, 4, Game.service.tanks[0].userData.visual.color);
			}
			else if (Game.service.tanks.length == 0) {
				// Total annihilation
				showTitle("No Survivors", delay, 4, Color.WHITE);
			}
			else {
				// Game continues
				Game.service.currentPlayerIndex = (Game.service.currentPlayerIndex + 1) % Game.service.tanks.length; // Next player's turn.
				
				// Rotate the foreground so that the current player is upright
				var cx:Number = Game.service.terrain.terrainWidth / 2;
				var cy:Number = Game.service.terrain.terrainHeight / 2;
				var wc:Vec2 = Game.service.tanks[Game.service.currentPlayerIndex].worldCOM;
				var dir:Vec2 = Vec2.get(wc.x - cx, wc.y - cy);
				var finalRotation:Number = -dir.angle + Math.PI/2;
			
				var fgrot:Tween = new Tween(Game.service.foreground, 1, Transitions.EASE_IN_OUT);
				fgrot.animate("rotation", finalRotation);
				Game.service.simulator.add(fgrot);
				
				var bgrot:Tween = new Tween(Game.service.background, 1, Transitions.EASE_IN_OUT);
				bgrot.animate("rotation", finalRotation * 0.86);
				Game.service.simulator.add(bgrot);

				// Kick off the new player turn
				Game.service.planter.start(Game.service.tanks[Game.service.currentPlayerIndex].worldCOM, vortexPhase);
				showTitle("Player Up", 0, 1, Game.service.tanks[Game.service.currentPlayerIndex].userData.visual.color);
			}
		}

		private static function vortexPhase():void
		{
			showTitle("The Winds of Fate", 0, 1, Game.service.tanks[Game.service.currentPlayerIndex].userData.visual.color);
			Game.service.windWidget.start(onVortexConfirmed);
		}
		
		private static function onVortexConfirmed():void
		{
			simulationPhase();
		}
	}
}