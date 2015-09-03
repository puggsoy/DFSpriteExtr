package;

import easyconsole.Begin;
import format.png.Data;
import format.png.Reader;
import format.png.Tools;
import format.png.Writer;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Path;
import haxe.zip.InflateImpl;
import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.FileSeek;

class Main 
{
	private var inFile:String;
	private var verbose:Bool = false;
	
	public function new()
	{
		Begin.init();
		Begin.usage = '${Path.withoutExtension(Path.withoutDirectory(Sys.executablePath()))} inFile [-v]\n    inFile: The file to extract from.\n    [-v]: Optional verbose output. Add to get A LOT of debug output stuff.';
		Begin.functions = [null, loadFile];
		Begin.parseArgs();
	}
	
	/**
	 * Loads sprite set and then outputs all the frames
	 * @param	filePath
	 */
	private function loadFile()
	{
		if (!FileSystem.exists(Begin.args[0]))
		{
			Sys.println('Can\'t find file ${Begin.args[0]}!');
			Sys.exit(2);
		}
		
		if (Begin.args.length > 1 && Begin.args[1] == '-v') verbose = true;
		
		Sys.println('Loading file...');
		
		var f:FileInput = File.read(Begin.args[0]);
		var spriteSet:SpriteSet = new SpriteSet(f);
		f.close();
		
		Sys.println('Extracting...');
		
		//Loop through the sprites
		for (i in 0...spriteSet._spriteCount)
		{
			saveFrames(spriteSet, i);
		}
	}
	
	/**
	 * Saves all the frames of a given sprite from a spriteset
	 * @param	s
	 * @param	spriteNm
	 */
	private function saveFrames(s:SpriteSet, spriteNm:Int)
	{
		var sprite:DFSprite = s._sprites[spriteNm];
		Sys.println('${sprite.path}: ${sprite.name}');
		vout('====================');
		
		//Loop through the frames
		for (i in 0...sprite.frameCount)
		{
			vout('vvvvvvvvvvvvvvvvvvvv');
			vout('Frame $i');
			vout('^^^^^^^^^^^^^^^^^^^^');
			
			var frame:DFFrame = sprite.frames[i];
			var subCount:Int = frame.subCount;
			
			var sub:DFSubSprite = sprite.subSprites[frame.subStart];
			
			//Find frame boundaries
			var l:Int = sub.subX + sub.rectSub.left;
			var t:Int = sub.subY + sub.rectSub.top;
			var r:Int = sub.subX + sub.rectSub.right;
			var b:Int = sub.subY + sub.rectSub.bottom;
			
			for (i in 1...frame.subCount)
			{
				sub = sprite.subSprites[frame.subStart + i];
				
				l = Std.int(Math.min(l, sub.subX + sub.rectSub.left));
				t = Std.int(Math.min(t, sub.subY + sub.rectSub.top));
				r = Std.int(Math.max(r, sub.subX + sub.rectSub.right));
				b = Std.int(Math.max(b, sub.subY + sub.rectSub.bottom));
			}
			
			vout('Bounds - l: $l, t: $t, r: $r, b: $b');
			
			//This is gonna be our frame
			var outDat:BitmapData = new BitmapData(r - l, b - t, (frame.hasAlpha == 1), 0);
			var border:Int = s._pageBorder;
			
			vout('Dimensions: ${outDat.rect}');
			vout('hasAlpha: ${frame.hasAlpha}');
			
			//Construct the frame from sub-sprites
			for (i in 0...frame.subCount)
			{
				vout('--------------------');
				vout('Sub-sprite ${frame.subStart + i}');
				vout('--------------------');
				
				sub = sprite.subSprites[frame.subStart + i];
				var subX:Int = sub.subX + sub.rectSub.left - l;
				var subY:Int = sub.subY + sub.rectSub.top - t;
				var rect:DFRect = sub.rectSub;
				
				vout('pageIndex: ${sub.pageIndex}');
				vout('subX: $subX, subY: $subY');
				vout('rect: $rect');
				
				//Make the page
				var ba:ByteArray = ByteArray.fromBytes(InflateImpl.run(new BytesInput(s._pages[sub.pageIndex].bitmapCompressed)));
				var page:BitmapData = new BitmapData(s._pageSize + (border * 2), s._pageSize + (border * 2), outDat.transparent, 0);
				page.setPixels(page.rect, ba);
				
				//Grab sub-sprite from page
				outDat.copyPixels(page, new Rectangle(border + rect.left, border + rect.top, rect.right - rect.left, rect.bottom - rect.top), new Point(subX, subY));
			}
			
			var path:String = Path.addTrailingSlash('extracted/${sprite.path}');//Subdirectory is necessary because some paths start with the same name as the file
			
			if (!FileSystem.exists(path) || !FileSystem.isDirectory(path))
			{
				FileSystem.createDirectory(path);
			}
			
			//Save the frame
			var pngDat:Data = Tools.build32BGRA(outDat.width, outDat.height, outDat.getPixels(outDat.rect));
			var num:String = StringTools.lpad('${i + 1}', '0', 4);
			var o:FileOutput = File.write('$path${sprite.name}$num.png');
			var w:Writer = new Writer(o);
			w.write(pngDat);
			o.close();
		}
	}
	
	/**
	 * This saves ALL the pages in a file in one big sheet. Useful for debugging and stuff I guess, although large ones tend to fail (e.g. intro1)
	 * @param	s
	 */
	private function savePages(s:SpriteSet)
	{
		var pages:Vector<DFPage> = s._pages;
		
		for (i in 0...s._pageCount)
		{
			var ba:ByteArray = ByteArray.fromBytes(InflateImpl.run(new BytesInput(s._pages[i].bitmapCompressed)));
			var page:BitmapData = new BitmapData(s._pageSize + (s._pageBorder * 2), s._pageSize + (s._pageBorder * 2), true, 0);
			page.setPixels(page.rect, ba);
			
			if (!FileSystem.exists('$inFile-out') || !FileSystem.isDirectory('$inFile-out'))
			{
				FileSystem.createDirectory('$inFile-out');
			}
			
			var pngDat:Data = Tools.build32BGRA(page.width, page.height, page.getPixels(page.rect));
			var o:FileOutput = File.write('$inFile-out\\$i.png');
			var w:Writer = new Writer(o);
			w.write(pngDat);
			o.close();
		}
	}
	
	/**
	 * For printing stuff when verbose output is flagged
	 * @param	msg
	 */
	private function vout(msg:Dynamic)
	{
		if (!verbose) return;
		
		Sys.println(msg);
	}
	
	static function main()
	{
		var obj:Main = new Main();
	}
}