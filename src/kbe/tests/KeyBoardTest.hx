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

	function testCopyProperties() {
		var key = new Key(1);
		var keyb = new Key(1);
		var fields:Map<String, Null<Dynamic>> = [
			"x" => 2.0,
			"y" => 3.0,
			"angle" => 0.5,
			"width" => 1.5,
			"height" => 2.5,
			"row" => 7,
			"column" => 10,
			"name" => "nm",
			"id" => null
		];
		for (field in Reflect.fields(keyb)) {
			Assert.isTrue(fields.exists(field));
			var value = fields.get(field);
			if (field != null) {
				Reflect.setField(keyb, field, value);
			}
		}
		Assert.notEquals(key.x, keyb.x);
		key.copyProperties(keyb);
		Assert.same(keyb, key);
	}
}
