package kbe.tests;

import utest.Assert;
import kbe.Editor;

class EditorTest extends utest.Test {
	function testConflictingKeys() {
		var keyboard = new KeyBoard();
		var editor = new Editor(keyboard);
		var key:Key;
		key = editor.newKey(); // 1
		key = editor.newKey(); // 2
		key.column = 1;
		key = editor.newKey(); // 3
		key.row = 1;
		var conflict = editor.getConflictingWiring();
		Assert.isTrue(conflict.length == 0);

		key = editor.newKey(); // 4
		key.column = 1;
		for (i in 0...3) {
			key = editor.newKey();
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
}
