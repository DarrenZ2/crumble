package
{
	import nape.phys.Material;
	
	import starling.filters.BlurFilter;
	import starling.textures.Texture;

	public final class SharedResources
	{
		[Embed(source="Bleeding_Cowboys.ttf", embedAsCFF="false", fontFamily="Title")]
		private static const TitleFont:Class;
		
		[Embed(source="bomb.png")]
		private static const Bomb:Class;
		
		[Embed(source="wind.png")]
		private static const Wind:Class;
		
		private var _circleStencil512:Stencil;			public function get circleStencil512():Stencil { return _circleStencil512; }
		private var _bombTexture:Texture;				public function get bombTexture():Texture { return _bombTexture; }
		private var _windTexture:Texture;				public function get windTexture():Texture { return _windTexture; }
		private var _glowFilter:BlurFilter;				public function get glowFilter():BlurFilter { return _glowFilter; }
		
		public const mineMaterial:Material = new Material(0.5);
		public const tankMaterial:Material = new Material(1.2, 0.05, 0.8);
		public const cordonMaterial:Material = new Material(1000.0);
		
		public function SharedResources()
		{
			_circleStencil512 = Stencil.createDebugCircle(512);
			_bombTexture = Texture.fromBitmap(new Bomb());
			_windTexture = Texture.fromBitmap(new Wind());
			_glowFilter = BlurFilter.createGlow(0x000000);
		}
		
		public function dispose():void
		{
			_circleStencil512.dispose();
			_bombTexture.dispose();
			_windTexture.dispose();
			_glowFilter.dispose();
		}
	}
}