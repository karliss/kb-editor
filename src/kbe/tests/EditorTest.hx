package kbe.tests;

import utest.Assert;
import kbe.Editor;

class EditorTest extends utest.Test {
	function testConflictingKeys() {
		var keyboard = new KeyBoard();
		var editor = new Editor(keyboard);
		var key:Key;
		key = editor.addNewKey(); // 1
		key = editor.addNewKey(); // 2
		key.column = 1;
		key = editor.addNewKey(); // 3
		key.row = 1;
		var conflict = editor.getConflictingWiring();
		Assert.isTrue(conflict.length == 0);

		key = editor.addNewKey(); // 4
		key.column = 1;
		for (i in 0...3) {
			key = editor.addNewKey();
			key.row = 5;
			key.column = 5;
		}
		conflict = editor.getConflictingWiring();
		Assert.equals(5, conflict.length);
		Assert.same([2, 4, 5, 6, 7], Lambda.map(conflict, key -> key.id));
	}

	// TODO:add key manipulation tests

	function testLayoutBasic() {
		var keyboard = new KeyBoard();
		var editor = new Editor(keyboard);
		Assert.equals(0, keyboard.layouts.length);
		var l0 = editor.newLayout();
		Assert.equals(1, keyboard.layouts.length);
		Assert.equals(l0, keyboard.layouts[0]);
		var l1 = editor.newLayout();
		Assert.equals(2, keyboard.layouts.length);

		editor.renameLayout(l0, "Layout0");
		Assert.equals("Layout0", keyboard.layouts[0].name);
		Assert.notEquals("Layout0", l1.name);

		editor.removeLayout(l0);
		Assert.equals(1, keyboard.layouts.length);
		Assert.equals(l1, keyboard.layouts[0]);
	}

	function testAddDown() {
		var editor = new Editor(new KeyBoard());
		var key0 = editor.addNewKey();
		Assert.equals(1, editor.state.keys.length);
		var key2 = editor.addDown(key0);
		Assert.equals(2, editor.state.keys.length);
		Assert.floatEquals(key0.x, key2.x);
		Assert.floatEquals(key0.y + 1, key2.y);
		Assert.floatEquals(key0.width, key2.width);
		Assert.equals(key0.column, key2.column);
		Assert.equals(key0.row + 1, key2.row);

		var keyBackup = key2.clone();
		// history
		editor.undoBuffer.undo();
		Assert.equals(1, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.same(keyBackup, editor.state.keys[1]);
	}

	function testAddRight() {
		var editor = new Editor(new KeyBoard());
		var key0 = editor.addNewKey();
		Assert.equals(1, editor.state.keys.length);
		var key1 = editor.addRight(key0);
		var key2 = editor.addRight(key1);
		Assert.equals(3, editor.state.keys.length);
		Assert.floatEquals(key0.y, key2.y);
		Assert.floatEquals(key0.x + 2, key2.x);
		Assert.floatEquals(key0.height, key2.height);
		Assert.equals(key0.column + 2, key2.column);
		Assert.equals(key0.row, key2.row);

		var keyBackup = key2.clone();

		// history
		editor.undoBuffer.undo();
		Assert.equals(2, editor.state.keys.length);
		editor.undoBuffer.undo();
		Assert.equals(1, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.equals(2, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.same(keyBackup, editor.state.keys[2]);
	}

	function testNewKey() {
		var editor = new Editor(new KeyBoard());
		var key0 = editor.addNewKey();
		Assert.equals(1, editor.state.keys.length);
		var id0 = key0.id;
		var key1 = editor.addNewKey();
		Assert.equals(2, editor.state.keys.length);
		var id1 = key1.id;
		Assert.notEquals(id0, id1);

		editor.undoBuffer.undo();
		Assert.equals(1, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.equals(id1, editor.state.keys[1].id);
	}

	function testRemoveKey() {
		var editor = new Editor(new KeyBoard());
		var key0 = editor.addNewKey();
		Assert.equals(1, editor.state.keys.length);
		editor.removeKey(key0);
		Assert.equals(0, editor.state.keys.length);

		editor.undoBuffer.undo();
		Assert.equals(1, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.equals(0, editor.state.keys.length);
		editor.undoBuffer.undo();
		Assert.equals(1, editor.state.keys.length);
		editor.undoBuffer.undo();
		Assert.equals(0, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.equals(1, editor.state.keys.length);
		editor.undoBuffer.redo();
		Assert.equals(0, editor.state.keys.length);
	}

	function testModifyKeys() {
		var editor = new Editor(new KeyBoard());
		var keys = [editor.addNewKey(), editor.addNewKey(), editor.addNewKey()];

		var getRowColumn = id -> {
			var key = editor.getKeyboard().getKeyById(id);
			return [key.row, key.column];
		};
		Assert.equals(0, keys[0].row);
		Assert.equals(0, keys[0].column);

		editor.modifyKeys([], []);
		Assert.equals(3, editor.getKeyboard().keys.length);
		editor.modifyKeys([1, 3], [["row" => 1, "column" => 2], ["row" => 3, "column" => 4]]);
		Assert.same([1, 2], [keys[0].row, keys[0].column]);
		Assert.same([0, 0], [keys[1].row, keys[1].column]);
		Assert.same([3, 4], [keys[2].row, keys[2].column]);
		editor.undoBuffer.undo();
		for (i in 1...4) {
			var key = editor.getKeyboard().getKeyById(i);
			Assert.same([0, 0], [key.row, key.column]);
		}
		editor.undoBuffer.redo();
		Assert.same([1, 2], getRowColumn(1));
		Assert.same([0, 0], getRowColumn(2));
		Assert.same([3, 4], getRowColumn(3));
	}

	function testAddLayoutMapping() {
		var editor = new Editor(new KeyBoard());
		for (i in 0...10) {
			editor.addNewKey();
		}
		var keyboard = editor.getKeyboard();
		var layout = editor.newLayoutFromKeys(editor.getKeyboard().keys);

		Assert.equals(null, layout.mappingFromGrid(1));
		Assert.equals(0, layout.mappingToGrid(1).length);

		editor.addLayoutMapping(layout, 1, 2);

		Assert.equals(2, layout.mappingFromGrid(1));
		Assert.same([1], layout.mappingToGrid(2));

		editor.addLayoutMapping(layout, 1, 3);

		Assert.equals(3, layout.mappingFromGrid(1));
		Assert.same([1], layout.mappingToGrid(3));
		Assert.same([], layout.mappingToGrid(2));

		editor.addLayoutMapping(layout, 4, 3);

		Assert.equals(3, layout.mappingFromGrid(4));
		Assert.equals(3, layout.mappingFromGrid(1));

		var sorted = (d:Array<Int>) -> {
			var result = d.copy();
			result.sort((x, y) -> (x - y));
			return result;
		};
		Assert.same([1, 4], sorted(layout.mappingToGrid(3)));
		Assert.same([], layout.mappingToGrid(2));

		editor.addLayoutMappingFromLayoutExclusive(layout, 7, 3);

		Assert.same([7], layout.mappingToGrid(3));
		Assert.equals(3, layout.mappingFromGrid(7));
		Assert.equals(null, layout.mappingFromGrid(4));
		Assert.equals(null, layout.mappingFromGrid(1));

		editor.undoBuffer.undo();
		editor.undoBuffer.redo();

		layout = editor.getKeyboard().layouts[0];
		Assert.same([7], layout.mappingToGrid(3));
		Assert.equals(3, layout.mappingFromGrid(7));
		Assert.equals(null, layout.mappingFromGrid(4));
		Assert.equals(null, layout.mappingFromGrid(1));
	}
}
