package;
import haxe.io.Bytes;

/**
 * Holds info for a page in a sprite set
 */
class DFPage
{
	public var x:Int;
	public var y:Int;
	public var bitmapSize:Int;
	public var bitmapCompressed:Bytes;
	
	public function new() {}
}