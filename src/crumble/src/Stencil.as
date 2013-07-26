package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import starling.display.Image;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;

	public final class Stencil
	{
		private var _rootBitmapData:BitmapData;
		private var _rootBitmapRegion:Rectangle;
		private var _rect:Rectangle;
		private var _texture:Texture;
		private var _eraseImage:Image;
		private var _addImage:Image;
		
		public function get rect():Rectangle 
		{
			return _rect;
		}
		
		// Operations are not unified. A backing store of the texture (rootBitmapData) is required
		// to support CPU operations.
		public function Stencil(rootBitmapData:BitmapData, rootTexture:Texture, rootBitmapRegion:Rectangle)
		{
			_rootBitmapData = rootBitmapData;
			_rootBitmapRegion = rootBitmapRegion;
			_rect = new Rectangle(0, 0, rootBitmapRegion.width, rootBitmapRegion.height);
			if (rootTexture != null) {
				_texture = Texture.fromTexture(rootTexture, rootBitmapRegion);
				_eraseImage = new Image(_texture);
				_eraseImage.blendMode = BlendMode.ERASE;
				_addImage = new Image(_texture);
				_addImage.blendMode = BlendMode.NORMAL;
			}
		}
		
		// Do not use in final builds! One-off resources like this will make rendering many different
		// stencils inefficient, so try to batch texture and bitmap data into atlases instead.
		public static function createDebugCircle(radius:Number):Stencil
		{
			var s:Shape = new Shape();
			s.graphics.beginFill(0xffffff, 1.0);
			s.graphics.drawCircle(radius, radius, radius);
			s.graphics.endFill();
			
			var bitmapData:BitmapData = new BitmapData(radius*2, radius*2, true, 0);
			bitmapData.draw(s);

			var texture:Texture = Texture.fromBitmapData(bitmapData, false, true, 1);
			
			return new Stencil(bitmapData, texture, texture.frame);
		}
		
		public static function createFromBitmap(bitmap:Bitmap):Stencil
		{
			var texture:Texture = Texture.fromBitmap(bitmap);
			return new Stencil(bitmap.bitmapData, texture, bitmap.bitmapData.rect);
		}

		public function dispose():void
		{
			_addImage.dispose();
			_eraseImage.dispose();
			_texture.dispose();
			// Don't dispose _rootBitmapData here. It is not ours to dispose.
		}
		
		public function subtractFromBitmapData(transform:Matrix, target:BitmapData):void
		{
			target.draw(_rootBitmapData, transform, null, BlendMode.SUBTRACT);//TODO: fix clipping: _rootBitmapRegion);
		}
		
		public function addToBitmapData(transform:Matrix, target:BitmapData):void
		{
			target.draw(_rootBitmapData, transform, null, BlendMode.ALPHA);
		}

		public function subtractFromRenderTexture(transform:Matrix, target:RenderTexture):void
		{
			target.draw(_eraseImage, transform); 
		}

		public function addToRenderTexture(transform:Matrix, target:RenderTexture):void
		{
			target.draw(_addImage, transform); 
		}
		
		// Writes data to a transform matrix so that it will center the stencil at the given
		// position (centerx, centery) and rotate the given angle in radians.
		public function matrixScaleRotateCenterInplace(scalex:Number, scaley:Number, angle:Number, centerx:Number, centery:Number, result:Matrix):void
		{
			result.identity();
			result.rotate(angle);
			result.scale(scalex, scaley);
			result.translate(centerx - scalex * _rootBitmapRegion.width/2, centery - scaley * _rootBitmapRegion.height/2);		
		}
	}
}