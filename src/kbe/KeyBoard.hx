package kbe;

import kbe.UndoBuffer.Clonable;
import haxe.ds.Vector;

class KeyboardLayout {
	public var name:String = "";
	public var keys = new Array<Key>();
	public var mapping = new Map<Int, Int>();

	public function new() {}

	public function clone():KeyboardLayout {
		var result = new KeyboardLayout();
		result.name = name;
		for (key in keys) {
			result.keys.push(key.clone());
		}
		result.mapping = mapping.copy();
		return result;
	}

	public function mappingFromGrid(gridId:Int):Null<Int> {
		return mapping.get(gridId);
	}

	public function mappingToGrid(layoutId:Int):Array<Int> {
		var result = [];
		for (key => value in mapping) {
			if (value == layoutId) {
				result.push(key);
			}
		}
		return result;
	}

	public function addMapping(gridId:Int, layoutId:Int) {
		if (layoutId < 0) {
			mapping.remove(gridId);
		}
		mapping.set(gridId, layoutId);
	}

	public function addExclusiveMapping(gridId:Int, layoutId:Int) {
		var existingMapping = mappingToGrid(layoutId);
		for (id in existingMapping) {
			mapping.remove(id);
		}
		mapping.set(gridId, layoutId);
	}
}

class KeyBoard implements Clonable<KeyBoard> {
	public var keys(default, null):Array<Key> = new Array<Key>();
	public var description = new Map<String, Dynamic>();
	public var layouts = new Array<KeyboardLayout>();

	public function new() {}

	public function clone():KeyBoard {
		var result = new KeyBoard();
		result.description = description.copy();
		for (key in keys) {
			result.keys.push(key.clone());
		}
		for (layout in layouts) {
			result.layouts.push(layout.clone());
		}
		return result;
	}

	public function addKey(key:Key):Key {
		keys.push(key);
		return key;
	}

	public function removeKey(key:Key) {
		keys.remove(key);
	}

	public function createKey():Key {
		return new Key(getNextId());
	}

	public function createAndAddKey():Key {
		var key = createKey();
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

	public function getKeyById(id:Int) {
		for (key in keys) {
			if (key.id == id) {
				return key;
			}
		}
		return null;
	}

	public function getLayoutByName(name:String):Null<KeyboardLayout> {
		for (layout in layouts) {
			if (layout.name == name) {
				return layout;
			}
		}
		return null;
	}

	public function renameLayout(oldName:String, newName:String) {
		var layout = getLayoutByName(oldName);
		var conflict = getLayoutByName(newName);
		if (layout != null && conflict == null) {
			layout.name = newName;
		}
	}

	public function removeLayout(name:String) {
		layouts.remove(getLayoutByName(name));
	}
}
