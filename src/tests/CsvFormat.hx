package tests;

import utest.Assert;
import CSVFormat;

class CsvFormat extends utest.Test {
	var field:String;

	// synchronous setup
	public function setup() {
		field = "some";
	}

	function testEmpty() {
		var keyboard = new KeyBoard();
		var exporter = new CSVExporter();
		var importer = new CSVImporter();
		var exported = exporter.convert(keyboard);
		var imported = importer.convert(exported);
		Assert.equals(0, keyboard.keys.length);
	}

	function testBasic() {
		var keyboard = new KeyBoard();
		keyboard.addKey(new Key(0));
		var key:Key;
		key = new Key(1);
		key.x = 1;
		key.y = 2;
		key.width = 1.5;
		key.height = 2;
		key.row = 3;
		key.column = 4;
		key.name = "name";
		keyboard.addKey(key);
		var exporter = new CSVExporter();

		var importer = new CSVImporter();
		var exported = exporter.convert(keyboard);
		var imported = importer.convert(exported);
		Assert.equals(2, imported.keys.length);
		Assert.same(keyboard.keys, imported.keys);
	}
}
