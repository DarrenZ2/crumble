package
{
	import nape.phys.Material;
	
	import starling.filters.BlurFilter;

	public final class SharedResources
	{
		[Embed(source="Bleeding_Cowboys.ttf", embedAsCFF="false", fontFamily="Title")]
		public static const TitleFont:Class;

		private var _circleStencil512:Stencil;			public function get circleStencil512():Stencil { return _circleStencil512; }
		private var _glowFilter:BlurFilter;				public function get glowFilter():BlurFilter { return _glowFilter; }
		
		public const mineMaterial:Material = new Material(0.5);
		public const tankMaterial:Material = new Material(1.2, 0.05, 0.8);
		public const cordonMaterial:Material = new Material(1000.0);
		
		public function SharedResources()
		{
			_circleStencil512 = Stencil.createDebugCircle(512);
			_glowFilter = BlurFilter.createGlow(0x000000);
		}
		
		public function dispose():void
		{
			_circleStencil512.dispose();
			_glowFilter.dispose();
		}
	}
}