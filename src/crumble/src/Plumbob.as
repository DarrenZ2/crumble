package
{
	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	
	import nape.geom.Vec2;
	
	import starling.animation.IAnimatable;
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.utils.deg2rad;
	import starling.events.Event;
	import starling.core.Starling;

	public final class Plumbob extends Sprite implements IAnimatable
	{
		private var accelerometer:Accelerometer;
		private var border1:Image;
		private var border2:Image;
		private var border3:Image;
		private var border4:Image;
		private const indicatorRadius:Number = 180;
		private const zeroBias:Number = deg2rad(90);
		private const maxAngle:Number = deg2rad(100);
		private const minAngle:Number = deg2rad(-100);
		private const angleSnap:Number = deg2rad(10);
		private var _currentAngle:Number = 0;				public function get currentAngle():Number { return _currentAngle; }
		private var _confirmButton:Button;
		private var _onConfirmed:Function;
		private var _lockedIn:Boolean;
		
		public function advanceTime(deltaTime:Number):void
		{
			rotation += _currentAngle * deltaTime * 5;
			rotation %= 2*Math.PI;

			var a:Number = Math.abs(_currentAngle);
			var dir:Number = (_currentAngle < 0) ? -1 : 1;
			var sx:Number = Math.min(Math.max(a / 0.5, 1), 2);
			
			// adjust length, thickness and opacity according to speed
			border1.scaleX = border2.scaleX = border3.scaleX = border4.scaleX = dir * sx;
			border1.scaleY = border2.scaleY = border3.scaleY = border4.scaleY = -sx;
			border1.alpha = border2.alpha = border3.alpha = border4.alpha = a*2;
		}
		
		public function start(onConfirmed:Function): void
		{
			_lockedIn = false;
			_currentAngle = 0;
			visible = true;
			_confirmButton.visible = true;
			_confirmButton.addEventListener(Event.TRIGGERED, internalOnConfirmed);
			_onConfirmed = onConfirmed;
			Starling.juggler.add(this);
		}
		
		private function unhookConfirmButton():void
		{
			_confirmButton.visible = false;
			_confirmButton.removeEventListener(Event.TRIGGERED, internalOnConfirmed);
			_onConfirmed = null;
		}

		private function internalOnConfirmed(event:Event):void
		{
			if (_onConfirmed != null) {
				_onConfirmed();
			}
			_lockedIn = true;
			unhookConfirmButton();
		}
		
		public function stop() : void
		{
			_currentAngle = 0;
			_lockedIn = false;
			Starling.juggler.remove(this);
			visible = false;
			unhookConfirmButton();
		}

		public function Plumbob()
		{
			accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE, onAccelerometerUpdate);
			
			// length of border triangles indicate rotational acceleration
			border1 = new Image(Game.service.shared.windTexture);
			border2 = new Image(Game.service.shared.windTexture);
			border3 = new Image(Game.service.shared.windTexture);
			border4 = new Image(Game.service.shared.windTexture);

			border1.pivotX = border2.pivotX = border3.pivotX = border4.pivotX = border1.width/2;
			border1.pivotY = border2.pivotY = border3.pivotY = border4.pivotY = border1.height/2;

			// circumscribe the radius
			border1.rotation = 0;
			border3.rotation = deg2rad(90);
			border2.rotation = deg2rad(180);
			border4.rotation = deg2rad(270);
			
			var r:Number = indicatorRadius;
			
			border1.x =  0;	border1.y = -r;
			border2.x =  0;	border2.y =  r;
			border3.x =  r;	border3.y =  0;
			border4.x = -r;	border4.y =  0;
			
			// display the widgets
			addChild(border1);
			addChild(border2);
			addChild(border3);
			addChild(border4);

			this.touchable = false;
			this.visible = false;
			
			Game.service.foreground.addChild(this);
			x = Game.service.terrain.terrainWidth / 2;
			y = Game.service.terrain.terrainHeight / 2;
			
			// add a button to confirm the setting when the plumbob widget is visible
			_confirmButton = new Button(Game.service.shared.windTexture);
			_confirmButton.width = stage.stageWidth / 2;
			_confirmButton.height = stage.stageHeight / 10;
			_confirmButton.x = stage.stageWidth / 2 - _confirmButton.width / 2;
			_confirmButton.y = stage.stageHeight - _confirmButton.height - stage.stageHeight / 20;
			_confirmButton.visible = false;
			Game.service.hud.addChild(_confirmButton);
		}
		
		private function onAccelerometerUpdate(event:AccelerometerEvent):void
		{
			if (visible && !_lockedIn) 
			{
				var v:Vec2 = new Vec2(-event.accelerationX, event.accelerationY);
				
				if (v.length >= 0.5) {
					const twopi:Number = 2*Math.PI;
					var rot:Number = (twopi + v.angle + zeroBias) % twopi - Math.PI; // zeroBias moves the 0 point to the 'bottom' and the -+pi singularity to the 'top'
					rot = (Math.floor((rot + twopi) / angleSnap + 0.5) * angleSnap) - twopi;
					
					if (rot < minAngle || rot > maxAngle) {
						_currentAngle = 0; // player tilted too far
					}
					else {
						_currentAngle = rot;
					}
				}
				else {
					_currentAngle = 0; // player has the phone lying flat
					// TODO: read from z-axis instead?
				}
			}
		}
	}
}