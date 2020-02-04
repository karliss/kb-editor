package kbe;

import kbe.UndoBuffer.Clonable;
import haxe.ds.Vector;

class KeyboardLayout {
	public var name:String = "";
	public var keys = new Array<Key>();

	private var mapping = new Map<Int, Int>();
	private var reverseMapping = new Map<Int, Array<Int>>();

	public function new() {}

	public function clone():KeyboardLayout {
		var result = new KeyboardLayout();
		result.name = name;
		for (key in keys) {
			result.keys.push(key.clone());
		}
		result.mapping = mapping.copy();
		result.reverseMapping = new Map<Int, Array<Int>>();
		for (key => value in reverseMapping) {
			result.reverseMapping.set(key, value.copy());
		}
		return result;
	}

	public function mappingFromGrid(gridId:Int):Null<Int> {
		return mapping.get(gridId);
	}

	public function mappingToGrid(layoutId:Int):Array<Int> {
		var result = reverseMapping.get(layoutId);
		if (result == null) {
			return [];
		}
		return result.copy();
	}

	public function addMapping(gridId:Int, layoutId:Int) {
		removeSingleMapping(gridId);
		if (layoutId >= 0) {
			mapping.set(gridId, layoutId);
			var reverse = reverseMapping.get(layoutId);
			if (reverse == null) {
				reverseMapping.set(layoutId, [gridId]);
			} else {
				reverse.push(gridId);
			}
		}
	}

	private function removeAllMappingFromReverse(reverseId:Int) {
		var reverse = reverseMapping.get(reverseId);
		if (reverse != null) {
			for (value in reverse) {
				mapping.remove(value);
			}
			reverseMapping.remove(reverseId);
		}
	}

	private function removeSingleMapping(gridId:Int) {
		if (gridId < 0) {
			return;
		}
		var current = mapping.get(gridId);
		if (current != null) {
			var reverse = reverseMapping.get(current);
			reverse.remove(gridId);
		}
		mapping.remove(gridId);
	}

	public function addExclusiveMapping(gridId:Int, layoutId:Int) {
		removeAllMappingFromReverse(layoutId);
		addMapping(gridId, layoutId);
	}

	public function autoConnectPairs(keyboard:KeyBoard, comparator:(Key, Key) -> Float, maxDistance = 0.5) {
		for (keyboardKey in keyboard.keys) {
			var nearest:Key = null;
			var nearestDistance = maxDistance + 1;
			for (layoutKey in keys) {
				var d = comparator(keyboardKey, layoutKey);
				if (d < nearestDistance) {
					nearest = layoutKey;
					nearestDistance = d;
				}
			}
			if (nearest != null && nearestDistance < maxDistance) {
				addMapping(keyboardKey.id, nearest.id);
			}
		}
	}

	@:generic
	public function autoConnect<T>(keyboard:KeyBoard, groupFunction:Null<Key->T>, comparator:(Key, Key) -> Float = null, maxDistance:Float = 0.5) {
		var createGroups = (keys:Array<Key>) -> {
			var result = new Map<T, Array<Key>>();
			for (key in keys) {
				var groupId = groupFunction(key);
				var group:Null<Array<Key>> = result.get(groupId);
				if (group == null) {
					group = new Array<Key>();
					result.set(groupId, group);
				}
				group.push(key);
			}
			return result;
		};
		var groupSize = (group:Map<T, Array<Key>>) -> {
			var result = 0;
			for (_ in group) {
				result++;
			}
			return result;
		};
		if (groupFunction != null) {
			var groupsLayout = createGroups(keys);
			var groupsKeyboard = createGroups(keyboard.keys);
			if (groupSize(groupsLayout) != 1 && groupSize(groupsKeyboard) != 1) {
				for (groupId => group in groupsKeyboard) {
					var layoutGroup = groupsLayout.get(groupId);
					if (layoutGroup == null) {
						continue;
					}
					if (group.length == 1 && layoutGroup.length == 1) {
						addMapping(group[0].id, layoutGroup[0].id);
					} else if (comparator != null && group.length == layoutGroup.length && group.length < 3) {
						for (keyboardKey in group) {
							var nearest:Key = null;
							var nearestDistance = maxDistance + 1;
							for (layoutKey in layoutGroup) {
								var d = comparator(keyboardKey, layoutKey);
								if (d < nearestDistance) {
									nearest = layoutKey;
									nearestDistance = d;
								}
							}
							if (nearest != null && nearestDistance < maxDistance) {
								addMapping(keyboardKey.id, nearest.id);
							}
						}
					} // else if group sizes mismatch better be safe and don't connect at all, in case of large groups groupFunction is likely bad indicator
				}
				return;
			}
			if (comparator != null) {
				autoConnectPairs(keyboard, comparator, maxDistance);
			}
		}
	}

	private static function keyDistance(a:Key, b:Key):Float {
		return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
	}

	public function connectByNameAndPos(keyboard:KeyBoard) {
		autoConnect(keyboard, key -> key.name, keyDistance);
	}

	public function connectByPos(keyboard:KeyBoard) {
		autoConnectPairs(keyboard, keyDistance, 0.01);
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
