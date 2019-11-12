package tests;

import haxe.io.Bytes;
import utest.Assert;
import KBLEFormat;

class KBLEFormat extends utest.Test {
	function testImportEmpty() {
		var importer = new KBLEImporter();
		var keyboard = importer.convert(Bytes.ofString('[]'));
		Assert.isTrue(keyboard.keys.length == 0);

		keyboard = importer.convert(Bytes.ofString('[[],[],[]]'));
		Assert.isTrue(keyboard.keys.length == 0);

		keyboard = importer.convert(Bytes.ofString('[[{"w": 2}],[],[]]'));
		Assert.isTrue(keyboard.keys.length == 0);
	}

	function testImportBasic() {
		var importer = new KBLEImporter();
		var keyboard = importer.convert(Bytes.ofString('[["a", "b"],["c", "d"]]'));
		Assert.equals(4, keyboard.keys.length);
		Assert.same({x: 0, y: 0}, keyboard.keys[0].point());
		Assert.same({x: 1, y: 0}, keyboard.keys[1].point());
		Assert.same({x: 0, y: 1}, keyboard.keys[2].point());
		Assert.same({x: 1, y: 1}, keyboard.keys[3].point());
	}

	function testImportOffset() {
		var importer = new KBLEImporter();
		var keyboard = importer.convert(Bytes.ofString('[[{"x":0.5, "y":0.5},"a", "b"],["c", {"x":-0.25}, "d"],[{"y": -0.25}, "e", {"y":0.25}, "f"], ["g"]]'));
		Assert.same({x: 0.5, y: 0.5}, keyboard.keys[0].point());
		Assert.same({x: 1.5, y: 0.5}, keyboard.keys[1].point());
		Assert.same({x: 0, y: 1.5}, keyboard.keys[2].point());
		Assert.same({x: 0.75, y: 1.5}, keyboard.keys[3].point());
		Assert.same({x: 0, y: 2.25}, keyboard.keys[4].point());
		Assert.same({x: 1, y: 2.5}, keyboard.keys[5].point());
		Assert.same({x: 0, y: 3.5}, keyboard.keys[6].point());
	}

	function testSize() {
		var importer = new KBLEImporter();
		var keyboard = importer.convert(Bytes.ofString('[[{"w":1.5, "h": 2},"a", "b"],["c", {"w":2, "h":2}, "d"], ["e"]]'));
		Assert.same({x: 0, y: 0}, keyboard.keys[0].point());
		Assert.equals(1.5, keyboard.keys[0].width);
		Assert.equals(2, keyboard.keys[0].height);
		Assert.same({x: 1.5, y: 0}, keyboard.keys[1].point());
		Assert.equals(1, keyboard.keys[1].width);
		Assert.equals(1, keyboard.keys[1].height);
		Assert.same({x: 0, y: 1}, keyboard.keys[2].point());
		Assert.equals(1, keyboard.keys[2].width);
		Assert.equals(1, keyboard.keys[2].height);
		Assert.same({x: 1, y: 1}, keyboard.keys[3].point());
		Assert.equals(2, keyboard.keys[3].width);
		Assert.equals(2, keyboard.keys[3].height);
		Assert.same({x: 0, y: 2}, keyboard.keys[4].point());
		Assert.equals(1, keyboard.keys[4].width);
		Assert.equals(1, keyboard.keys[4].height);
	}

	function testProperties() {
		var importer = new KBLEImporter();
		var keyboard = importer.convert(Bytes.ofString('
[
  {
    "backcolor": "#d13232",
    "name": "name value",
    "author": "author here",
    "notes": "adsf asdfnotes notes notes",
    "background": {
      "name": "Carbon fibre 5",
      "style": "background-image: url(\'/bg/carbonfibre/carbon_texture1876.jpg\');"
    },
    "radii": "40px",
    "switchMount": "alps",
    "switchBrand": "alps",
    "switchType": "SKBL/SKBM",
    "pcb": true,
    "plate": true
  },
  ["a", "b"]
]'));
		Assert.equals(2, keyboard.keys.length);
		Assert.equals("name value", keyboard.description["name"]);
		Assert.equals("author here", keyboard.description["author"]);
	}
}
