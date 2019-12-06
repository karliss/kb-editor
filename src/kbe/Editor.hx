package kbe;

import kbe.UndoBuffer.UndoExecutor;
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

enum EditorAction {
	AddKey(key:Key);
	RemoveKey(id:Int);
	ModifyKey(id:Int, properties:Key);
	NewLayout(layout:KeyboardLayout);
	RenameLayout(oldName:String, newName:String);
	RemoveLayout(name:String);
	AddLayoutMapping(layout:String, gridId:Int, layoutId:Int);
	AddLayoutExclusiveMapping(layout:String, gridId:Int, layoutId:Int);
}

class Editor implements UndoExecutor<KeyBoard, EditorAction> {
	var keyboard:KeyBoard;

	public var undoBuffer(default, null):UndoBuffer<KeyBoard, EditorAction>;

	public var state(get, set):KeyBoard;

	public var alignment:Float = 0.25;
	public var alignButtons:Bool = true;

	public function new(keyboard:KeyBoard) {
		this.keyboard = keyboard;
		this.undoBuffer = new UndoBuffer<KeyBoard, EditorAction>(this);
	}

	public function setKeyboard(keyboard:KeyBoard) {
		this.keyboard = keyboard;
	}

	public function getKeyboard():KeyBoard {
		return keyboard;
	}

	function set_state(v:KeyBoard):KeyBoard {
		setKeyboard(v);
		return keyboard;
	}

	function get_state():KeyBoard {
		return this.keyboard;
	}

	public function applyAction(a:EditorAction):Dynamic {
		switch (a) {
			case AddKey(key):
				{
					var k = key.clone();
					keyboard.addKey(k);
					return k;
				}
			case RemoveKey(id):
				keyboard.removeKey(keyboard.getKeyById(id));

			case ModifyKey(id, prop):
				keyboard.getKeyById(id).copyProperties(prop);

			case NewLayout(layout):
				{
					var v = layout.clone();
					keyboard.layouts.push(v);
					return v;
				}
			case RenameLayout(oldName, newName):
				keyboard.renameLayout(oldName, newName);
			case RemoveLayout(name):
				keyboard.removeLayout(name);
			case AddLayoutMapping(layout, gridId, layoutId):
				keyboard.getLayoutByName(layout).addMapping(gridId, layoutId);
			case AddLayoutExclusiveMapping(layout, gridId, layoutId):
				keyboard.getLayoutByName(layout).addExclusiveMapping(gridId, layoutId);
		}
		return null;
	}

	public function mergeActions(a:EditorAction, b:EditorAction):Null<EditorAction> {
		switch [a, b] {
			case [ModifyKey(id1, _), ModifyKey(id2, properties2)] if (id1 == id2):
				return ModifyKey(id1, properties2);
			case [AddKey(key), ModifyKey(id2, properties2)] if (key.id == id2):
				return AddKey(properties2);
			default:
				return null;
		}
	}

	public function runAction(a:EditorAction, merge = false):Dynamic {
		return undoBuffer.runAction(a, merge);
	}

	function createKey():Key {
		return keyboard.createKey();
	}

	public function addNewKey():Key {
		return runAction(AddKey(createKey()));
	}

	public function addDown(prevKey:Key):Key {
		var key = createKey();
		key.y = prevKey.y + prevKey.height;
		key.x = prevKey.x;
		key.width = prevKey.width;
		key.row = prevKey.row + 1;
		key.column = prevKey.column;
		return runAction(AddKey(key));
	}

	public function addRight(prevKey:Key):Key {
		var key = createKey();
		key.y = prevKey.y;
		key.x = prevKey.x + prevKey.width;
		key.height = prevKey.height;
		key.row = prevKey.row;
		key.column = prevKey.column + 1;
		return runAction(AddKey(key));
	}

	public function removeKey(key:Key) {
		runAction(RemoveKey(key.id));
	}

	function alignKey(key:Key, force:Bool = false) {
		var rnd = function(val:Float, step:Float):Float {
			return Math.fround(val / step) * step;
		};
		if (alignButtons || force) {
			var st:Float = alignment;
			key.x = rnd(key.x, st);
			key.y = rnd(key.y, st);
		}
	}

	public function moveKey(key:Key, x:Float, y:Float, merge = false) {
		var key2 = key.clone();
		key2.x = x;
		key2.y = y;
		if (alignButtons) {
			alignKey(key2);
		}
		runAction(ModifyKey(key.id, key2), merge);
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
		return runAction(NewLayout(layout));
	}

	public function newLayoutFromKeys(keys:Array<Key>):KeyboardLayout {
		var layout = new KeyboardLayout();
		layout.name = 'Layout${keyboard.layouts.length}';
		var newKeys = keys.map(key -> key.clone());
		layout.keys = newKeys;
		return runAction(NewLayout(layout));
	}

	public function renameLayout(layout:KeyboardLayout, name:String) {
		runAction(RenameLayout(layout.name, name));
	}

	public function removeLayout(layout:KeyboardLayout) {
		runAction(RemoveLayout(layout.name));
	}

	public function addLayoutMapping(layout:KeyboardLayout, gridId:Int, layoutId:Int) {
		runAction(AddLayoutMapping(layout.name, gridId, layoutId));
	}

	public function addLayoutMappingFromLayoutExclusive(layout:KeyboardLayout, gridId:Int, layoutId:Int) {
		runAction(AddLayoutExclusiveMapping(layout.name, gridId, layoutId));
	}
}
