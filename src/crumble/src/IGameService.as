package
{
	import nape.space.Space;
	
	import starling.display.DisplayObjectContainer;

	public interface IGameService
	{
		function get space():Space;
		function get display():DisplayObjectContainer;
		function get classes():GameClasses;
		function get terrain():Terrain;
	}
}