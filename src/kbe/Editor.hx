package kbe;

import kbe.KeyBoard.RowCol;
import kbe.KeyBoard.WireMapping;
import kbe.UndoBuffer.UndoExecutor;
import kbe.KeyBoard.KeyboardLayout;

using thx.Arrays;

class IPoint {
	public var x:Int;
	public var y:Int;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

enum EditorAction {
	ActionList(actions:Array<EditorAction>);
	AddKey(key:Key);
	RemoveKeys(id:Array<Int>);
	ModifyKey(id:Int, properties:Key);
	ModifyKeys(id:Array<Int>, properties:Array<Map<String, Dynamic>>);
	MoveKeys(id:Array<Int>, positions:Array<Key.Point>);
	NewLayout(layout:KeyboardLayout);
	RenameLayout(oldName:String, newName:String);
	RemoveLayout(name:String);
	UpdateLayout(name:String, layout:KeyboardLayout);
	AddLayoutMapping(layout:String, gridId:Int, layoutId:Int);
	AddLayoutExclusiveMapping(layout:String, gridId:Int, layoutId:Int);
	UpdateWireMapping(rows:Null<WireMapping>, columns:Null<WireMapping>);
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

	public function applyAction(a:EditorAction):Null<Dynamic> {
		switch (a) {
			case ActionList(actions):
				for (action in actions) {
					applyAction(action);
				}
			case AddKey(key):
				{
					var k = key.clone();
					keyboard.addKey(k);
					return k;
				}
			case RemoveKeys(ids):
				{
					for (id in ids) {
						var key = keyboard.getKeyById(id);
						if (key != null) {
							keyboard.removeKey(key);
						}
					}
				}

			case ModifyKey(id, prop):
				var key = keyboard.getKeyById(id);
				if (key == null) {
					throw "Key not found";
				}
				key.copyProperties(prop);
			case ModifyKeys(id, prop):
				modifyKeysImpl(id, prop);

			case MoveKeys(ids, positions):
				moveKeysImpl(ids, positions);

			case NewLayout(layout):
				{
					var v = layout.clone();
					keyboard.addLayout(v);
					return v;
				}
			case RenameLayout(oldName, newName):
				keyboard.renameLayout(oldName, newName);
			case RemoveLayout(name):
				keyboard.removeLayout(name);
			case UpdateLayout(name, layout):
				return keyboard.updateLayout(name, layout.clone());
			case AddLayoutMapping(layout, gridId, layoutId):
				var layout = keyboard.getLayoutByName(layout);
				if (layout != null) {
					layout.addMapping(gridId, layoutId);
				} else {
					trace('Warning layout not found, should not happen');
				}
			case AddLayoutExclusiveMapping(layout, gridId, layoutId):
				var layout = keyboard.getLayoutByName(layout);
				if (layout != null) {
					layout.addExclusiveMapping(gridId, layoutId);
				} else {
					trace('Warning layout not found, should not happen');
				}

			case UpdateWireMapping(rows, columns):
				if (rows != null) {
					keyboard.rowMapping = rows.clone();
				}
				if (columns != null) {
					keyboard.columnMapping = columns.clone();
				}
		}
		return null;
	}

	private function modifyKeysImpl(ids:Array<Int>, prop:Array<Map<String, Dynamic>>) {
		for (i in 0...ids.length) {
			var key = keyboard.getKeyById(ids[i]);
			if (key == null) {
				throw "Key not found";
			}
			for (name => value in prop[i]) {
				Reflect.setField(key, name, value);
			}
		}
	}

	private function moveKeysImpl(ids:Array<Int>, positions:Array<Key.Point>) {
		var index = 0;
		for (id in ids) {
			var key = keyboard.getKeyById(id);
			if (key != null) {
				key.x = positions[index].x;
				key.y = positions[index].y;
			}
			index++;
		}
	}

	public function mergeActions(a:EditorAction, b:EditorAction):Null<EditorAction> {
		switch [a, b] {
			case [ModifyKey(id1, _), ModifyKey(id2, properties2)] if (id1 == id2):
				return ModifyKey(id1, properties2);
			case [ModifyKeys(ids1, prop1), ModifyKeys(ids2, prop2)] if (ids1.equals(ids2)):
				var res = prop1.copy();
				for (i in 0...prop1.length) {
					var mapA = res[i];
					var mapB = prop2[i];
					for (key => value in mapB) {
						mapA.set(key, value);
					}
				}
				return ModifyKeys(ids1, res);
			case [AddKey(key), ModifyKey(id2, properties2)] if (key.id == id2):
				return AddKey(properties2);
			case [MoveKeys(ids1, pos1), MoveKeys(ids2, pos2)] if (ids1.equals(ids2)):
				return MoveKeys(ids1, pos2);
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
		runAction(RemoveKeys([key.id]));
	}

	public function removeKeys(keys:Array<Key>) {
		runAction(RemoveKeys(keys.map(key -> key.id)));
	}

	function alignPoint(pos:Key.Point, force:Bool = false):Key.Point {
		var rnd = function(val:Float, step:Float):Float {
			return Math.fround(val / step) * step;
		};
		if (alignButtons || force) {
			var st:Float = alignment;
			pos.x = rnd(pos.x, st);
			pos.y = rnd(pos.y, st);
		}
		return pos;
	}

	function alignKey(key:Key, force:Bool = false) {
		var p = alignPoint({x: key.x, y: key.y});
		key.x = p.x;
		key.y = p.y;
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

	public function moveKeys(ids:Array<Int>, positions:Array<Key.Point>, merge = false) {
		var alignedPositions = positions.map(position -> alignPoint({x: position.x, y: position.y}));
		runAction(MoveKeys(ids.copy(), alignedPositions), merge);
	}

	public function alignKeys(mainKey:Key, keys:Array<Key>, y:Bool = true) {
		var resultKeys = new Array<Int>();
		var resultPos = new Array<Key.Point>();
		for (key in keys) {
			if (key != mainKey) {
				resultKeys.push(key.id);
				if (y) {
					resultPos.push({x: key.x, y: mainKey.y});
				} else {
					resultPos.push({x: mainKey.x, y: key.y});
				}
			}
		}
		runAction(MoveKeys(resultKeys, resultPos), false);
	}

	function comparePropertyChanges(a:Map<String, Dynamic>, b:Map<String, Dynamic>) {
		for (key => value in a) {
			if (b.get(key) != value) {
				return false;
			}
		}
		for (key => value in b) {
			if (a.get(key) != value) {
				return false;
			}
		}
		return true;
	}

	public function modifyKeys(ids:Array<Int>, properties:Array<Map<String, Dynamic>>, mergeDuplicate:Bool = true) {
		var prevAction = undoBuffer.lastAction();
		var merge = false;
		if (mergeDuplicate && prevAction != null) {
			switch (prevAction) {
				case ModifyKeys(prevId, prevProperties):
					if (prevId.equals(ids)) {
						merge = true;
						for (i in 0...properties.length) {
							if (!comparePropertyChanges(prevProperties[i], properties[i])) {
								merge = false;
								break;
							}
						}
					}
				default:
			}
		}
		runAction(ModifyKeys(ids, properties), merge);
	}

	public function getConflictingWiring(logicalMatrix:Bool = false):Array<Key> {
		var badKeys = new Array<Key>();

		var cmp = function(a:RowCol, b:RowCol):Int {
			if (a.col != b.col) {
				return a.col - b.col;
			}
			return a.row - b.row;
		};

		var posCount = new OrderedMap<RowCol, Int>(cmp);
		for (key in keyboard.keys) {
			var pos = keyboard.getKeyPos(logicalMatrix, key);
			var count = posCount.get(pos);
			if (count == null) {
				posCount.set(pos, 1);
			} else {
				posCount.set(pos, count + 1);
			}
		}
		for (key in keyboard.keys) {
			var c = posCount.get(keyboard.getKeyPos(logicalMatrix, key));
			if (c != null && c > 1) {
				badKeys.push(key);
			}
		}
		return badKeys;
	}

	public function newLayout():KeyboardLayout {
		var layout = new KeyboardLayout();
		layout.name = "Layout";
		return runAction(NewLayout(layout));
	}

	public function newLayoutFromKeys(keys:Array<Key>, identityMapping:Bool):KeyboardLayout {
		var layout = new KeyboardLayout();
		layout.name = 'Layout';
		layout.setKeys(keyboard.keys, identityMapping);
		return runAction(NewLayout(layout));
	}

	public function addLayout(layout:KeyboardLayout):KeyboardLayout {
		return runAction(NewLayout(layout));
	}

	public function renameLayout(layout:KeyboardLayout, name:String) {
		runAction(RenameLayout(layout.name, name));
	}

	public function removeLayout(layout:KeyboardLayout) {
		runAction(RemoveLayout(layout.name));
	}

	public function addLayoutMapping(layout:KeyboardLayout, gridId:Int, layoutId:Int) {
		if (layout.synchronised) {
			return;
		}
		runAction(AddLayoutMapping(layout.name, gridId, layoutId));
	}

	public function addLayoutMappingFromLayoutExclusive(layout:KeyboardLayout, gridId:Int, layoutId:Int) {
		if (layout.synchronised) {
			return;
		}
		runAction(AddLayoutExclusiveMapping(layout.name, gridId, layoutId));
	}

	public function updateLayout(name:String, layout:KeyboardLayout):KeyboardLayout {
		return runAction(UpdateLayout(name, layout.clone()));
	}

	public function updateRowMapping(?rows:WireMapping, ?columns:WireMapping) {
		runAction(UpdateWireMapping(rows, columns));
	}

	public function updateRowOrColumnMapping(rows:WireMapping, row:Bool) {
		if (row) {
			runAction(UpdateWireMapping(rows, null));
		} else {
			runAction(UpdateWireMapping(null, rows));
		}
	}

	public function autoIncrementWiringColumns(keys:Array<Key>) {
		if (keys.length == 0) {
			return;
		}
		keys.sort((a, b) -> {
			var d = a.x - b.x;
			if (d < 0) {
				return -1;
			} else if (d > 0) {
				return 1;
			}
			return 0;
		});
		var column = keys[0].column;
		var ids = keys.map(key -> key.id);
		var changes = new Array<Map<String, Dynamic>>();
		for (key in keys) {
			changes.push(["column" => column]);
			column += 1;
		}
		modifyKeys(ids, changes);
	}

	public function addWiringRow(row:Bool) {
		var rows = (row ? keyboard.rowMapping : keyboard.columnMapping).clone();
		var count = rows.rows;
		rows.rows = count + 1;
		rows.setMatrixRow(count, count);
		if (row) {
			updateRowMapping(rows);
		} else {
			updateRowMapping(null, rows);
		}
	}

	public function resizeWiringToKeyboard() {
		var size = keyboard.getWiringMatrixSize();
		var rows = keyboard.rowMapping.clone();
		var cols = keyboard.columnMapping.clone();
		rows.resize(size.row);
		cols.resize(size.col);
		updateRowMapping(rows, cols);
	}

	public function swapWiringRowColumnProperties() {
		var rows = keyboard.rowMapping.clone();
		var cols = keyboard.columnMapping.clone();
		updateRowMapping(cols, rows); // intentionally swapped
	}

	public function swapWiringRowColumnAssignment() {
		var keys:Array<Int> = [];
		var properties:Array<Map<String, Dynamic>> = [];
		for (key in keyboard.keys) {
			keys.push(key.id);
			var changes = new Map<String, Dynamic>();
			changes.set("row", key.column); // intentionally swapped
			changes.set("column", key.row);
			properties.push(changes);
		}
		runAction(ActionList([
			ModifyKeys(keys, properties),
			UpdateWireMapping(keyboard.columnMapping.clone(), keyboard.rowMapping.clone()) // intentionally swapped
		]));
	}

	public function swapTwoWiringRows(row:Bool, a:Int, b:Int) {
		var rows = (row ? keyboard.rowMapping : keyboard.columnMapping).clone();
		var keys:Array<Int> = [];
		var properties:Array<Map<String, Dynamic>> = [];
		for (key in keyboard.keys) {
			var currentPos = row ? key.row : key.column;
			if (currentPos == a || currentPos == b) {
				var other = b;
				if (currentPos == b) {
					other = a;
				}
				keys.push(key.id);
				var changes = new Map<String, Dynamic>();
				changes.set(row ? "row" : "column", other);
				properties.push(changes);
			}
		}
		modifyKeys(keys, properties);
	}
}
