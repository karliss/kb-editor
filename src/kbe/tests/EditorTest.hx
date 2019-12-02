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
}
