package kbe.tests;

import haxe.io.Bytes;
import kbe.KeyBoard.KeyboardLayout;
import utest.Assert;
import kbe.TKBEditorFormat;
import haxe.Json;

class TKBEFormat extends utest.Test {
	function testEmpty() {
		var keyboard = new KeyBoard();
		var exporter = new TKBEExporter();
		var importer = new TKBEImporter();
		var exported = exporter.convert(keyboard);
		var imported = importer.convert(exported);
		Assert.equals(0, keyboard.keys.length);
		var exported2 = exporter.convert(imported);
		Assert.same(exported, exported2);
	}

	function testBasic() {
		var keyboard = new KeyBoard();
		keyboard.addKey(new Key(1));
		var key:Key;
		key = new Key(2);
		key.x = 1;
		key.y = 2;
		key.width = 1.5;
		key.height = 2;
		key.row = 3;
		key.column = 4;
		key.name = "name";
		keyboard.addKey(key);
		var exporter = new TKBEExporter();

		var importer = new TKBEImporter();
		var exported = exporter.convert(keyboard);
		var data = Json.parse(exported.toString());
		var expectedKeys:Array<Dynamic> = [
			{
				"id": 1,
				"x": 0,
				"y": 0,
				"col": 0,
				"row": 0
			},
			{
				"id": 2,
				"name": "name",
				"x": 1,
				"y": 2,
				"w": 1.5,
				"h": 2,
				"col": 4,
				"row": 3
			}
		];
		var expected = {
			"keys": expectedKeys
		};
		Assert.same(expected, data);
		var imported = importer.convert(exported);
		Assert.equals(2, imported.keys.length);
		Assert.same(keyboard.keys, imported.keys);
		var exported2 = exporter.convert(imported);
		Assert.same(exported, exported2);
	}

	function testLayout() {
		var keyboard = new KeyBoard();
		var exporter = new TKBEExporter();
		var importer = new TKBEImporter();

		keyboard.addKey(new Key(10));
		keyboard.addKey(new Key(11));
		keyboard.addKey(new Key(12));
		keyboard.addKey(new Key(13));

		var layout1 = new KeyboardLayout();
		layout1.name = "synchronized_layout";
		layout1.synchronised = true;
		keyboard.addLayout(layout1);

		var layout2 = new KeyboardLayout();
		layout2.name = "l2";
		var lk1 = new Key(1);
		var lk2 = new Key(2);
		var lk3 = new Key(3);
		lk2.x = 1;
		lk3.y = 1;

		layout2.keys.push(lk1);
		layout2.keys.push(lk2);
		layout2.keys.push(lk3);

		layout2.addMapping(10, 1);
		layout2.addMapping(12, 12);
		layout2.addMapping(11, 12);

		keyboard.addLayout(layout2);

		var exported = exporter.convert(keyboard);
		var imported = importer.convert(exported);
		Assert.same(keyboard, imported);
		var exported2 = exporter.convert(keyboard);
		Assert.same(exported, exported2);
	}
}
