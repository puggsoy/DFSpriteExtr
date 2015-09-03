package;
import haxe.ds.Vector;
import haxe.io.Bytes;

/**
 * Holds data for a specific sprite (animation). This includes frames, sub-sprites, name, and so on.
 */
class DFSprite
{
	public var frames:Vector<DFFrame>;
	public var subSprites:Vector<DFSubSprite>;
	
	public var name:String;
	public var path:String;
	public var userData:Bytes;
	public var frameCount:Int;
	public var subSpriteCount:Int;
	public var originX:Int;
	public var originY:Int;
	public var paletteIndex:Int;
	public var paletteCount:Int;
	
	public var spriteSet:SpriteSet;
	
	public function new(fc:Int, ssc:Int) 
	{
		frames = new Vector<DFFrame>(fc);
		for (i in 0...fc) frames[i] = new DFFrame();
		subSprites = new Vector<DFSubSprite>(ssc);
		for (i in 0...ssc) subSprites[i] = new DFSubSprite();
	}
}