package kbe;

import thx.OrderedMap.EnumValueOrderedMap;
import haxe.io.Bytes;
import haxe.ui.data.ArrayDataSource;
import kbe.KeyBoard.KeyboardLayout;
import kbe.CSVFormat.CSVExporter;
import kbe.KBLEFormat.KBLEImporter;
import kbe.CSVFormat.CSVImporter;
import kbe.Exporter.Importer;

class IPoint {
	public var x:Int;
	public var y:Int;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

class Editor {
	var keyboard:KeyBoard;

	public var alignment:Float = 0.25;
	public var alignButtons:Bool = true;

	public function new(keyboard:KeyBoard) {
		this.keyboard = keyboard;
	}

	public function setKeyboard(keyboard:KeyBoard) {
		this.keyboard = keyboard;
	}

	public function getKeyboard():KeyBoard {
		return keyboard;
	}

	public function newKey():Key {
		return keyboard.createKey();
	}

	public function addDown(prevKey:Key):Key {
		var key = newKey();
		key.y = prevKey.y + prevKey.height;
		key.x = prevKey.x;
		key.width = prevKey.width;
		key.row = prevKey.row + 1;
		key.column = prevKey.column;
		return key;
	}

	public function addRight(prevKey:Key):Key {
		var key = newKey();
		key.y = prevKey.y;
		key.x = prevKey.x + prevKey.width;
		key.height = prevKey.height;
		key.row = prevKey.row;
		key.column = prevKey.column + 1;
		return key;
	}

	public function removeKey(key:Key) {
		keyboard.removeKey(key);
	}

	public function alignKey(key:Key, force:Bool = false) {
		var rnd = function(val:Float, step:Float):Float {
			return Math.fround(val / step) * step;
		};
		if (alignButtons || force) {
			var st:Float = alignment;
			key.x = rnd(key.x, st);
			key.y = rnd(key.y, st);
		}
	}

	public function moveKey(key:Key, x:Float, y:Float) {
		key.x = x;
		key.y = y;
		if (alignButtons) {
			alignKey(key);
		}
	}

	public function getConflictingWiring():Array<Key> {
		var badKeys = new Array<Key>();

		var cmp = function(a:IPoint, b:IPoint):Int {
			if (a.x != b.x) {
				return a.x - b.x;
			}
			return a.y - b.y;
		};

		var posCount = new OrderedMap<IPoint, Int>(cmp);
		for (key in keyboard.keys) {
			var pos = new IPoint(key.row, key.column);
			var count = posCount.get(pos);
			if (count == null) {
				posCount.set(pos, 1);
			} else {
				posCount.set(pos, count + 1);
			}
		}
		for (key in keyboard.keys) {
			var c = posCount.get(new IPoint(key.row, key.column));
			if (c != null && c > 1) {
				badKeys.push(key);
			}
		}
		return badKeys;
	}

	public function newLayout():KeyboardLayout {
		var layout = new KeyboardLayout();
		layout.name = 'Layout${keyboard.layouts.length}';
		keyboard.layouts.push(layout);
		return layout;
	}

	public function newLayoutFromKeys(keys:Array<Key>):KeyboardLayout {
		var layout = newLayout();
		var newKeys = keys.map(key -> key.clone());
		layout.keys = newKeys;
		return layout;
	}

	public function renameLayout(layout:KeyboardLayout, name:String) {
		layout.name = name;
	}

	public function removeLayout(layout:KeyboardLayout) {
		keyboard.layouts.remove(layout);
	}
}
