package;

class Key {
	public var x:Float = 0;
	public var y:Float = 0;
	public var angle:Float = 0;
	public var width:Float = 1;
	public var height:Float = 1;
	public var row:Int = 0;
	public var column:Int = 0;
	public var id(default, null):Int = 0;
	public var name:String = "";

	public function new(id:Int) {
		this.id = id;
	}
}
