package;

import haxe.io.Bytes;
import haxe.ui.data.ArrayDataSource;
import CSVFormat.CSVExporter;
import KBLEFormat.KBLEImporter;
import CSVFormat.CSVImporter;
import Exporter.Importer;

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
}
