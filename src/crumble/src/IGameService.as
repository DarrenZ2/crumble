package
{
	import nape.phys.Body;
	import nape.space.Space;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Stage;

	public interface IGameService
	{
		function get stage():Stage;
		function get space():Space;
		function get background():DisplayObjectContainer;
		function get foreground():DisplayObjectContainer;
		function get hud():DisplayObjectContainer;
		function get classes():GameClasses;
		function get terrain():Terrain;
		function get plumbob():Plumbob;
		function get planter():Planter;
		function get shared():SharedResources;
		function updateBodyVisuals(body:Body):void;
		function get tanks():Vector.<Body>;
		function get currentPlayerIndex():int;
		function set currentPlayerIndex(value:int):void;
		function pausePhysics():void;
		function resumePhysics():void;
	}
}