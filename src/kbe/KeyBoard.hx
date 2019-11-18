package kbe;

import haxe.ds.Vector;

class KeyboardLayout {
	public var name:String = "";
	public var keys = new Array<Key>();
	public var mapping = new Map<Int, Int>();

	public function new() {}

	public function mappingFromGrid(a:Int):Null<Int> {
		return mapping.get(a);
	}

	public function mappingToGrid(a:Int):Array<Int> {
		var result = [];
		for (key => value in mapping) {
			if (value == a) {
				result.push(key);
			}
		}
		return result;
	}
}

class KeyBoard {
	public var keys(default, null):Array<Key> = new Array<Key>();
	public var description = new Map<String, Dynamic>();
	public var layouts = new Array<KeyboardLayout>();

	public function new() {}

	public function addKey(key:Key):Key {
		keys.push(key);
		return key;
	}

	public function removeKey(key:Key) {
		keys.remove(key);
	}

	public function createKey():Key {
		var key = new Key(getNextId());
		addKey(key);
		return key;
	}

	public function getNextId():Int {
		if (keys.length == 0) {
			return 1;
		}
		var used = new Vector<Int>(keys.length);
		var i = 0;
		for (key in keys) {
			used[i++] = key.id;
		}
		var compareInt = function(a, b):Int {
			if (a < b)
				return -1;
			else if (a > b)
				return 1;
			return 0;
		}
		#if eval
		{
			var a = used.toArray();
			a.sort(compareInt);
			used = Vector.fromArrayCopy(a);
		}
		#else
		used.sort(compareInt);
		#end
		var last = 0;
		for (v in used) {
			if (v > last + 1) {
				return last + 1;
			}
			last = v;
		}
		return last + 1;
	}
}
