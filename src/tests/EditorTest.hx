package tests;

import utest.Assert;
import Editor;

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
}
