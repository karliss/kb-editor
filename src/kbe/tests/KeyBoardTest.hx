package kbe.tests;

import kbe.KeyBoard.KeyboardLayout;
import utest.Assert;

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

	function testLayoutCopy() {
		var layout1 = new KeyboardLayout();
		layout1.name = "l1";
		var key = new Key(1);
		key.name = "foo";
		layout1.keys.push(key);
		layout1.addMapping(1, 11);
		layout1.addMapping(2, 12);
		layout1.addMapping(3, 13);
		layout1.addMapping(4, 13);
		var layout2 = layout1.clone();
		Assert.notEquals(layout1, layout2);
		layout1.addMapping(1, -1);
		layout1.addMapping(2, -1);
		layout1.addMapping(3, -1);
		layout1.addMapping(4, -1);
		Assert.same("l1", layout2.name);
		layout1.keys.push(new Key(2));
		Assert.same([key], layout2.keys);
		Assert.notEquals(key, layout2.keys[0]);

		Assert.equals(11, layout2.mappingFromGrid(1));
		Assert.equals(12, layout2.mappingFromGrid(2));
		Assert.equals(13, layout2.mappingFromGrid(3));
		Assert.equals(13, layout2.mappingFromGrid(4));
		Assert.same([1], layout2.mappingToGrid(11));
		Assert.same([2], layout2.mappingToGrid(12));
		Assert.same([3, 4], layout2.mappingToGrid(13));
	}
}
