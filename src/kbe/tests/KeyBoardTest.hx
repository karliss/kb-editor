package kbe.tests;

import utest.Assert;
import kbe.Editor;

class KeyBoardTest extends utest.Test {
	function testConflictingKeys() {
		var keyboard = new KeyBoard();
		for (i in 0...10) {
			keyboard.createAndAddKey();
		}
		for (i in 0...10) {
			var key = new Key(100 + i);
			keyboard.addKey(key);
		}
		Assert.equals(keyboard.keys[0], keyboard.getKeyById(1));
		Assert.equals(keyboard.keys[5], keyboard.getKeyById(6));
		Assert.equals(keyboard.keys[10], keyboard.getKeyById(100));
		Assert.equals(keyboard.keys[11], keyboard.getKeyById(101));
		Assert.equals(null, keyboard.getKeyById(1000));
	}
}
