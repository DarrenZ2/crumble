package
{
	import nape.space.Space;
	
	import starling.display.DisplayObjectContainer;

	public interface IGameService
	{
		function get space():Space;
		function get background():DisplayObjectContainer;
		function get foreground():DisplayObjectContainer;
		function get classes():GameClasses;
		function get terrain():Terrain;
		function get shared():SharedResources;
	}
}