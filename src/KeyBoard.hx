import haxe.ds.Vector;

class KeyBoard {
	public var keys(default, null):List<Key> = new List<Key>();

	public function new() {}

	public function addKey(key:Key) {
		keys.add(key);
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
		if (keys.isEmpty()) {
			return 1;
		}
		var used = new Vector<Int>(keys.length);
		var i = 0;
		for (key in keys) {
			used[i++] = key.id;
		}
		used.sort(function(a, b):Int {
			if (a < b)
				return -1;
			else if (a > b)
				return 1;
			return 0;
		});
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
