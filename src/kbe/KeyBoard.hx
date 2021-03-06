package kbe;

import kbe.Editor.IPoint;
import kbe.UndoBuffer.Clonable;
import haxe.ds.Vector;

enum KeyboarLayoutAutoConnectMode {
	NamePos;
	NameOnly;
	Position;
}

typedef RowColNull = {
	row:Null<Int>,
	col:Null<Int>
}

typedef RowCol = {
	row:Int,
	col:Int
}

class KeyboardLayout {
	public var name:String = "Layout";
	public var keys = new Array<Key>();
	public var synchronised = false;

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
		result.synchronised = synchronised;
		return result;
	}

	public function getMapping():Map<Int, Int> {
		return mapping;
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

	public function hasLayoutMapping(layoutId:Int):Bool {
		var result = reverseMapping.get(layoutId);
		if (result == null) {
			return false;
		}
		return result.length > 0;
	}

	public function hasKeyboardMapping(keyboardId:Int):Bool {
		return mappingFromGrid(keyboardId) != null;
	}

	public function addMapping(gridId:Int, layoutId:Int) {
		removeSingleMapping(gridId);
		if (layoutId >= 0 && gridId >= 0) {
			mapping.set(gridId, layoutId);
			var reverse = reverseMapping.get(layoutId);
			if (reverse == null) {
				reverseMapping.set(layoutId, [gridId]);
			} else {
				reverse.push(gridId);
			}
		}
	}

	public function clearMapping() {
		mapping.clear();
		reverseMapping.clear();
	}

	private function removeAllMappingFromReverse(reverseId:Int) {
		if (reverseId < 0) {
			return;
		}
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
			if (reverse != null) {
				reverse.remove(gridId);
			}
		}
		mapping.remove(gridId);
	}

	public function addExclusiveMapping(gridId:Int, layoutId:Int) {
		removeAllMappingFromReverse(layoutId);
		addMapping(gridId, layoutId);
	}

	public function setKeys(keys:Array<Key>, identityMapping:Bool = true) {
		clearMapping();
		this.keys = keys.map(key -> key.clone());
		if (identityMapping) {
			for (key in keys) {
				addMapping(key.id, key.id);
			}
		}
	}

	public function autoConnectPairs(keyboard:KeyBoard, comparator:(Key, Key) -> Float, maxDistance = 0.5, unassigned:Bool = false) {
		if (!unassigned) {
			mapping.clear();
			reverseMapping.clear();
		}
		var keyboardKeys = keyboard.keys.filter(key -> !hasKeyboardMapping(key.id));
		var layoutKeys = keys.filter(key -> !hasLayoutMapping(key.id));
		for (keyboardKey in keyboardKeys) {
			var nearest:Null<Key> = null;
			var nearestDistance = maxDistance + 1;
			for (layoutKey in layoutKeys) {
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
	public function autoConnect<T>(keyboard:KeyBoard, groupFunction:Null<Key->T>, comparator:(Key, Key) -> Float = null, maxDistance:Float = 0.5,
			unassigned:Bool = false) {
		var createGroups = (keys:Array<Key>, groupFunction:Key->T) -> {
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
		if (!unassigned) {
			mapping.clear();
			reverseMapping.clear();
		}
		if (groupFunction != null) {
			var layoutKeys = keys.filter(key -> !hasLayoutMapping(key.id));
			var groupsLayout = createGroups(layoutKeys, groupFunction);
			var keyboardKeys = keyboard.keys.filter(key -> !mapping.exists(key.id));
			var groupsKeyboard = createGroups(keyboardKeys, groupFunction);
			if (!(groupSize(groupsLayout) == 1 && groupSize(groupsKeyboard) == 1 && keyboardKeys.length > 1)) {
				for (groupId => group in groupsKeyboard) {
					var layoutGroup = groupsLayout.get(groupId);
					if (layoutGroup == null) {
						continue;
					}
					if (group.length == 1 && layoutGroup.length == 1) {
						addMapping(group[0].id, layoutGroup[0].id);
					} else if (comparator != null && group.length == layoutGroup.length && group.length < 3) {
						for (keyboardKey in group) {
							var nearest:Null<Key> = null;
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
		}
		if (comparator != null) {
			autoConnectPairs(keyboard, comparator, maxDistance, unassigned);
		}
	}

	public function autoConnectInMode(keyboard:KeyBoard, mode:KeyboarLayoutAutoConnectMode, unassigned:Bool, maxDistance:Float = 0.5) {
		switch (mode) {
			case NamePos:
				autoConnect(keyboard, key -> key.name.toLowerCase(), keyDistance, maxDistance, unassigned);
			case NameOnly:
				autoConnect(keyboard, key -> key.name.toLowerCase(), null, maxDistance, unassigned);
			case Position:
				autoConnectPairs(keyboard, keyDistance, maxDistance, unassigned);
		}
	}

	public static function keyDistance(a:Key, b:Key):Float {
		return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
	}

	public function connectByNameAndPos(keyboard:KeyBoard) {
		autoConnect(keyboard, key -> key.name.toLowerCase(), keyDistance);
	}

	public function connectByPos(keyboard:KeyBoard) {
		autoConnectInMode(keyboard, KeyboarLayoutAutoConnectMode.Position, false, 0.01);
	}
}

class KeyBoard implements Clonable<KeyBoard> {
	public var keys(default, null):Array<Key> = new Array<Key>();
	public var description = new Map<String, Dynamic>();
	public var layouts(get, never):Vector<KeyboardLayout>;

	public var rowMapping(default, default) = new WireMapping();
	public var columnMapping(default, default) = new WireMapping();

	var _layouts = new Array<KeyboardLayout>();

	public function new() {}

	public function clone():KeyBoard {
		var result = new KeyBoard();
		result.description = description.copy();
		for (key in keys) {
			result.keys.push(key.clone());
		}
		for (layout in _layouts) {
			result._layouts.push(layout.clone());
		}
		result.rowMapping = rowMapping.clone();
		result.columnMapping = columnMapping.clone();
		return result;
	}

	public function get_layouts():Vector<KeyboardLayout> {
		return Vector.fromArrayCopy(_layouts.map(getResolvedLayout));
	}

	public function unresolved_layouts():Array<KeyboardLayout> {
		return this._layouts;
	}

	public function getResolvedLayout(layout:KeyboardLayout):KeyboardLayout {
		if (!layout.synchronised) {
			return layout;
		}
		var resolvedlayout = layout.clone();
		resolvedlayout.setKeys(keys);
		return resolvedlayout;
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

	public function getKeyById(id:Int):Null<Key> {
		for (key in keys) {
			if (key.id == id) {
				return key;
			}
		}
		return null;
	}

	public function getLayoutByName(name:String):Null<KeyboardLayout> {
		for (layout in _layouts) {
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
		var layout = getLayoutByName(name);
		if (layout != null) {
			_layouts.remove(layout);
		}
	}

	public function updateLayout(name:String, layout:KeyboardLayout):Null<KeyboardLayout> {
		for (i in 0..._layouts.length) {
			if (_layouts[i].name == name) {
				if (name != layout.name) {
					layout.name = getUnusedLayoutName(layout.name);
				}
				return _layouts[i] = layout;
			}
		}
		return null;
	}

	public function getUnusedLayoutName(name:String):String {
		var conflict = getLayoutByName(name);
		if (conflict == null) {
			return name;
		}
		var i:Int = 2;
		var MAX_LAYOUTS = 1000000;
		while (i < MAX_LAYOUTS) { // You really shouldn't have this many layouts
			var newName = name + '_$i';
			if (getLayoutByName(newName) == null) {
				return newName;
			}
			i += 1;
		}
		throw "Too many layouts";
	}

	public function addLayout(layout:KeyboardLayout):KeyboardLayout {
		layout.name = getUnusedLayoutName(layout.name);
		_layouts.push(layout);
		return layout;
	}

	public function getMatrixRow(electricRow:Int):Int {
		return rowMapping.getMatrixRow(electricRow);
	}

	public function getMatrixCol(electricCol:Int):Int {
		return columnMapping.getMatrixRow(electricCol);
	}

	public function getMatrixPos(key:Key):RowCol {
		return {row: getMatrixRow(key.row), col: getMatrixCol(key.column)};
	}

	public inline function getWiringPos(key:Key):RowCol {
		return {row: key.row, col: key.column};
	}

	public inline function getKeyPos(logicalMatrix:Bool, key:Key):RowCol {
		return logicalMatrix ? getMatrixPos(key) : getWiringPos(key);
	}

	public function getMatrixSize():RowCol {
		var rows = 0;
		var col = 0;
		for (key in keys) {
			var pos = getMatrixPos(key);
			if (pos.row + 1 > rows) {
				rows = pos.row + 1;
			}
			if (pos.col + 1 > col) {
				col = pos.col + 1;
			}
		}
		return {row: rows, col: col};
	}

	public function getWiringMatrixSize():RowCol {
		var rows = 0;
		var col = 0;
		for (key in keys) {
			var pos = getWiringPos(key);
			if (pos.row + 1 > rows) {
				rows = pos.row + 1;
			}
			if (pos.col + 1 > col) {
				col = pos.col + 1;
			}
		}
		return {row: rows, col: col};
	}
}

class WireMapping {
	public var hasWireColumn(default, set):Bool = false;
	public var columnNames(default, null) = new Array<String>();
	public var rows(get, set):Int;

	private var matrixRow = new Array<Int>();
	private var columns = new Array<Array<Null<Dynamic>>>();
	private var minRows:Int = 0;

	public function new() {
		addColumn("pin");
	}

	public function clone():WireMapping {
		var result = new WireMapping();
		result.hasWireColumn = this.hasWireColumn;
		result.columnNames = columnNames.copy();
		result.matrixRow = matrixRow.copy();
		result.columns = columns.map(col -> col.copy());
		result.minRows = minRows;
		return result;
	}

	public function addColumn(name:String):Int {
		var index = columns.length;
		columns.push(new Array<Dynamic>());
		columnNames.push(name);
		return index;
	}

	public inline function getColumnIndex(name:String):Int {
		return columnNames.indexOf(name);
	}

	public function removeColumn(name:String) {
		var column = getColumnIndex(name);
		if (column > -1) {
			columnNames.splice(column, 1);
			columns.splice(column, 1);
		}
	}

	public function get_rows():Int {
		var result = minRows;
		if (hasWireColumn && matrixRow.length > result) {
			result = matrixRow.length;
		}
		for (column in columns) {
			if (column.length > result) {
				result = column.length;
			}
		}
		return result;
	}

	public function set_rows(v:Int):Int {
		minRows = v;
		return v;
	}

	function set_hasWireColumn(v:Bool):Bool {
		hasWireColumn = v;
		if (!hasWireColumn) {
			matrixRow = [];
		}
		return v;
	}

	public function getMatrixRow(row:Int):Int {
		if (hasWireColumn && row < matrixRow.length) {
			return matrixRow[row];
		}
		return row;
	}

	public function setMatrixRow(row:Int, matrixRow:Int) {
		while (this.matrixRow.length <= row) {
			this.matrixRow.push(this.matrixRow.length);
		}
		this.matrixRow[row] = matrixRow;
	}

	public function getColumnValue(row:Int, columnIndex:Int):Null<Dynamic> {
		if (columnIndex < columns.length) {
			var column = columns[columnIndex];
			if (row < column.length) {
				return column[row];
			}
		}
		return null;
	}

	public function setColumnValue(row:Int, columnIndex:Int, value:Dynamic):Dynamic {
		var column = columns[columnIndex];
		while (column.length <= row) {
			column.push(null);
		}
		return column[row] = value;
	}

	public function resize(count:Int) {
		this.minRows = count;
		if (matrixRow.length > count) {
			matrixRow.resize(count);
		}
		for (column in columns) {
			if (column.length > count) {
				column.resize(count);
			}
		}
	}
}
