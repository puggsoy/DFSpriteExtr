package;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Path;
import sys.io.FileInput;

/**
 * Loads the sprite set
 */
class SpriteSet
{
	private static inline var _headerSize:Int = 6 + 2 * 6 + 4 * 2;// 6 char, 6 uint16, 2 uint32
	private static inline var _headerMagic:String = 'DF_SPR';
	private static inline var _formatVersion:Int = 0x2C;//Just an extra check I guess??
	
	public var _spriteCount:Int;
	public var _sprites:Vector<DFSprite>;
	
	public var _pageCount:Int;
	public var _pages:Vector<DFPage>;
	public var _pageSize:Int;
	public var _pageBorder:Int;
	
	public function new(fi:FileInput)
	{
		//Header
		//====================
		var b:Bytes = Bytes.alloc(_headerSize);
		fi.readFullBytes(b, 0, _headerSize);
		var headerData:BytesInput = new BytesInput(b);
		
		var magic:String = headerData.readString(6);
		
		if (magic != _headerMagic)
		{
			Sys.println('Invalid ID: $magic');
			Sys.exit(3);
		}
		
		var version:Int = headerData.readUInt16();
		
		if (version != _formatVersion)
		{
			Sys.println('Invalid version: ${StringTools.hex(version)}');
			Sys.exit(3);
		}
		
		var spriteCount:Int = headerData.readUInt16();
		var pageCount:Int = headerData.readUInt16();
		var pageSize:Int = headerData.readUInt16();
		var pageBorder:Int = headerData.readUInt16();
		var paletteCount:Int = headerData.readUInt16();
		
		var spriteDataSize:Int = headerData.readInt32();
		var pageDataSize:Int = headerData.readInt32();
		
		//Sprite Data
		//====================
		_spriteCount = spriteCount;
		_sprites = new Vector<DFSprite>(spriteCount);
		
		b = Bytes.alloc(spriteDataSize);
		fi.readFullBytes(b, 0, spriteDataSize);
		var spriteData:BytesInput = new BytesInput(b);
		
		for (i in 0...spriteCount)
		{
			var totalNameLength:Int = spriteData.readByte();
			var spriteName:String = spriteData.readString(totalNameLength);
			var pathLength:Int = spriteData.readByte();
			var spritePath:String = spriteData.readString(pathLength);
			//User Data (only useful for fonts, apparently)
			var userDataSize:Int = spriteData.readInt32();
			var userData:Bytes = null;
			if (userDataSize > 0)
			{
				userData = Bytes.alloc(userDataSize);
				spriteData.readFullBytes(userData, 0, userDataSize);
			}
			
			var frameCount:Int = spriteData.readUInt16();
			var subSpriteCount:Int = spriteData.readUInt16();
			var originX:Int = spriteData.readInt16();
			var originY:Int = spriteData.readInt16();
			var palette:Int = spriteData.readUInt16();
			var paletteCount:Int = spriteData.readByte();
			
			var sprite:DFSprite = new DFSprite(frameCount, subSpriteCount);
			
			//Frame data
			for (j in 0...frameCount)
			{
				var frame:DFFrame = sprite.frames[j];
				
				frame.frameIndex = spriteData.readUInt16();
				frame.timeStamp = spriteData.readUInt16();
				frame.rect = new DFRect(spriteData.readInt16(), spriteData.readInt16(), spriteData.readInt16(), spriteData.readInt16());
				frame.uvRect = new DFRect(spriteData.readUInt16(), spriteData.readUInt16(), spriteData.readUInt16(), spriteData.readUInt16());
				frame.subStart = spriteData.readInt32();
				frame.subCount = spriteData.readUInt16();
				frame.hasAlpha = spriteData.readByte();
			}
			
			//Sub sprite data
			for (j in 0...subSpriteCount)
			{
				sprite.subSprites[j].pageIndex = spriteData.readUInt16();
				sprite.subSprites[j].rectSub = new DFRect(spriteData.readByte(), spriteData.readByte(), spriteData.readByte(), spriteData.readByte());
				sprite.subSprites[j].subX = spriteData.readInt16();
				sprite.subSprites[j].subY = spriteData.readInt16();
			}
			
			sprite.name = spriteName;
			sprite.path = spritePath;
			sprite.userData = userData;
			sprite.frameCount = frameCount;
			sprite.subSpriteCount = subSpriteCount;
			sprite.originX = originX;
			sprite.originY = originY;
			sprite.paletteIndex = palette;
			sprite.paletteCount = paletteCount;
			
			sprite.spriteSet = this;
			_sprites[i] = sprite;
		}
		
		//Page Data
		//====================
		_pageCount = pageCount;
		_pages = new Vector<DFPage>(_pageCount);
		
		_pageSize = pageSize;
		_pageBorder = pageBorder;
		
		b = Bytes.alloc(pageDataSize);
		fi.readFullBytes(b, 0, pageDataSize);
		var pageData:BytesInput = new BytesInput(b);
		
		for (i in 0...pageCount)
		{
			var pageX:Int = pageData.readByte();
			var pageY:Int = pageData.readByte();
			var pageBitmapSize:Int = pageData.readInt32();
			
			var compressedBitmap:Bytes = Bytes.alloc(pageBitmapSize);
			pageData.readFullBytes(compressedBitmap, 0, pageBitmapSize);
			
			var page:DFPage = new DFPage();
			page.x = pageX;
			page.y = pageY;
			page.bitmapSize = pageBitmapSize;
			page.bitmapCompressed = compressedBitmap;
			
			_pages[i] = page;
		}
	}
}