package kbe;

typedef Point = {x:Float, y:Float}

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

	public function point():Point {
		return {x: x, y: y};
	}

	public function clone():Key {
		var key = new Key(this.id);
		key.copyProperties(this);

		return key;
	}

	public function copyProperties(key:Key) {
		this.id = key.id;
		x = key.x;
		y = key.y;
		angle = key.angle;
		width = key.width;
		height = key.height;
		row = key.row;
		column = key.column;
		name = key.name;
	}
}
