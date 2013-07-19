package
{
	import nape.callbacks.CbType;

	public final class GameClasses
	{
		private var _debugBox:DebugBoxClass;						public function get debugBox():DebugBoxClass { return _debugBox; }
		private var _mortar:MortarClass;							public function get mortar():MortarClass { return _mortar; }
		private const _physTerrainType:CbType = new CbType();		public function get physTerrainType():CbType { return _physTerrainType; }
		private const _physMissileType:CbType = new CbType();		public function get physMissileType():CbType { return _physMissileType; }

		public function GameClasses()
		{
			_debugBox = new DebugBoxClass();
			_mortar = new MortarClass();
		}
	}
}