package
{
	public final class GameClasses
	{
		private var _debugBox:DebugBoxClass;						public function get debugBox():DebugBoxClass { return _debugBox; }
		private var _mortar:MortarClass;							public function get mortar():MortarClass { return _mortar; }
		private var _tank:TankClass;								public function get tank():TankClass { return _tank; }

		public function GameClasses()
		{
			_debugBox = new DebugBoxClass();
			_mortar = new MortarClass();
			_tank = new TankClass();
		}
	}
}