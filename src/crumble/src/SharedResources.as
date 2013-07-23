package
{
	import nape.phys.Material;

	public final class SharedResources
	{
		private var _circleStencil512:Stencil;			public function get circleStencil512():Stencil { return _circleStencil512; }

		public const mineMaterial:Material = new Material(0.5);
		public const tankMaterial:Material = new Material(1.2);
		public const cordonMaterial:Material = new Material(1000.0);
		
		public function SharedResources()
		{
			_circleStencil512 = Stencil.createDebugCircle(512);
		}
		
		public function dispose():void
		{
			_circleStencil512.dispose();
		}
	}
}