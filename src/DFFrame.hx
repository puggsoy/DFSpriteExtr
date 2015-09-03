package;

/**
 * Holds data for a single frame of a sprite
 */
class DFFrame
{
	public var frameIndex:Int;
	public var timeStamp:Int;
	public var rect:DFRect;
	public var uvRect:DFRect;
	public var subStart:Int;
	public var subCount:Int;
	public var hasAlpha:Int;
	
	public function new() {}
}