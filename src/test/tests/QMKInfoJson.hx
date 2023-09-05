package kbe.tests;

import kbe.Key.Point;
import haxe.ds.HashMap;
import haxe.io.Bytes;
import utest.Assert;
import kbe.QMKInfoJson;

class QMKInfoJson extends utest.Test {
	function testImportEmpty() {
		var importer = new QMKInfoJsonImporter();
		var keyboard = importer.convert(Bytes.ofString('{}'));
		Assert.isTrue(keyboard.keys.length == 0);

		keyboard = importer.convert(Bytes.ofString('{"keyboard_name": "foo"}'));
		Assert.equals("foo", keyboard.description.get("keyboard_name"));
	}

	function testKeysBasic() {
		var importer = new QMKInfoJsonImporter();
		var data = '
{
	"keyboard_name": "TheKeyboard",
	"url": "",
	"maintainer": "maintainerName",
	"width": 2,
	"height": 2,
	"layouts": {
		"LAYOUT": {
		"key_count": 3,
		"layout": [{"label":"L00", "x":0, "y":0}, {"label":"L01", "x":1, "y":0}, {"label":"L11", "x":1, "y":1}]
		}
	}
}';
		var keyboard = importer.convert(Bytes.ofString(data));
		Assert.equals(3, keyboard.keys.length);
		Assert.same({x: 0, y: 0}, keyboard.keys[0].point());
		Assert.equals("L00", keyboard.keys[0].name);
		Assert.same({x: 1, y: 0}, keyboard.keys[1].point());
		Assert.equals("L01", keyboard.keys[1].name);
		Assert.same({x: 1, y: 1}, keyboard.keys[2].point());
		Assert.equals("L11", keyboard.keys[2].name);
	}

	function testKeyProperties() {
		var importer = new QMKInfoJsonImporter();
		var data = '
{
	"layouts": {
		"LAYOUT": {
		"key_count": 2,
		"layout": [{"label":"L00", "x":0.5, "y":1}, {"label":"L01", "x":2, "y":3, "w":2.25, "h":1.5, "r":90, "ks":[ [0,0], [1.5,0], [1.5,2], [0.25,2], [0.25,1], [0,1], [0,0] ]}]
		}
	}
}';
		var keyboard = importer.convert(Bytes.ofString(data));
		Assert.equals(2, keyboard.keys.length);
		var key0 = keyboard.keys[0];
		Assert.same({x: 0.5, y: 1}, key0.point());
		Assert.equals("L00", key0.name);
		Assert.floatEquals(1.0, key0.width);
		Assert.floatEquals(1.0, key0.height);

		var key1 = keyboard.keys[1];
		Assert.isFalse(key0.id == key1.id);
		Assert.same({x: 2.0, y: 3.0}, key1.point());
		Assert.equals("L01", key1.name);
		Assert.floatEquals(2.25, key1.width);
		Assert.floatEquals(1.5, key1.height);
		// rotation currently ignored
		// shape currently ignored
	}

	function testLayouts() {
		var importer = new QMKInfoJsonImporter();
		var data = '
{
	"layouts": {
		"LAYOUT": {
		"key_count": 3,
		"layout": [{"label":"L00", "x":0.0, "y":0.0}, {"label":"L01", "x":1, "y":0}, {"label":"L02", "x":2, "y":0}]
		},
		"LAYOUT2": {
			"key_count": 2,
			"layout": [{"label":"L00", "x":0, "y":0}, {"label":"L01", "x":1, "y":0}]
		}
	}
}';
		var keyboard = importer.convert(Bytes.ofString(data));
		Assert.equals(3, keyboard.keys.length);
		Assert.equals(2, keyboard.layouts.length);
		var layout0 = keyboard.layouts[0];
		Assert.equals("LAYOUT", layout0.name);
		Assert.equals(3, layout0.keys.length);
		Assert.equals("L00", layout0.keys[0].name);
		Assert.same({x: 0.0, y: 0.0}, layout0.keys[0].point());
		Assert.same({x: 2.0, y: 0.0}, layout0.keys[2].point());
		Assert.isFalse(layout0.keys[0].id == layout0.keys[1].id);
		Assert.isFalse(layout0.keys[0].id == layout0.keys[2].id);
		Assert.isFalse(layout0.keys[1].id == layout0.keys[2].id);

		var layout1 = keyboard.layouts[1];
		Assert.equals("LAYOUT2", layout1.name);
		Assert.equals(2, layout1.keys.length);
		Assert.equals("L00", layout1.keys[0].name);
		Assert.same({x: 0.0, y: 0.0}, layout1.keys[0].point());
		Assert.same({x: 1.0, y: 0.0}, layout1.keys[1].point());
	}

	function testLayoutMapping() {
		var importer = new QMKInfoJsonImporter();
		var data = '
{
	"layouts": {
		"LAYOUT": {
		"key_count": 3,
		"layout": [{"label":"L00", "x":0.0, "y":0.0}, {"label":"L01", "x":1, "y":0}, {"label":"L02", "x":2.25, "y":0}]
		},
		"LAYOUT2": {
			"key_count": 2,
			"layout": [{"label":"L00", "x":0, "y":0}, {"label":"L02", "x":2.0, "y":0}]
		}
	}
}';
		var keyboard = importer.convert(Bytes.ofString(data));
		var layout = keyboard.getLayoutByName("LAYOUT2");

		var getKeyByLabel = (keys:Array<Key>, name:String) -> {
			for (key in keys) {
				if (key.name == name) {
					return key;
				}
			}
			return null;
		};
		var main_key00 = getKeyByLabel(keyboard.keys, "L00");
		var layout_key00 = getKeyByLabel(layout.keys, "L00");
		Assert.isTrue(layout.mappingFromGrid(main_key00.id) == layout_key00.id);
		Assert.same([layout_key00.id], layout.mappingToGrid(layout_key00.id));

		var main_key01 = getKeyByLabel(keyboard.keys, "L01");
		Assert.equals(null, layout.mappingFromGrid(main_key01.id));
	}

	function testLayoutMappingShift() {
		var importer = new QMKInfoJsonImporter();
		var data = '
{
	"layouts": {
		"LAYOUT": {
		"key_count": 4,
		"layout": [{"label":"SHIFT", "x":0.0, "y":0.0}, {"label":"A", "x":1, "y":0}, {"label":"B", "x":2, "y":0}, {"label":"SHIFT", "x":3, "y":0}]
		},
		"LAYOUT2": {
			"key_count": 4,
			"layout": [{"label":"SHIFT", "x":0.0, "y":0.0}, {"label":"A", "x":1, "y":0}, {"label":"SHIFT", "x":3, "y":0}, {"label":"D", "x":2, "y":1}]
		}
	}
}';
		var keyboard = importer.convert(Bytes.ofString(data));
		var layout = keyboard.getLayoutByName("LAYOUT2");

		final EPS = 0.01;
		var getKeyByPos = (keys:Array<Key>, expect:Point) -> {
			for (key in keys) {
				if (Math.abs(key.x - expect.x) < EPS && Math.abs(key.y - expect.y) < EPS) {
					return key;
				}
			}
			return null;
		};

		var shift1 = getKeyByPos(keyboard.keys, {x: 0, y: 0});
		var shift1Layout = getKeyByPos(layout.keys, {x: 0, y: 0});
		Assert.equals(shift1Layout.id, layout.mappingFromGrid(shift1.id));
		Assert.same([shift1.id], layout.mappingToGrid(shift1Layout.id));

		var shift2 = getKeyByPos(keyboard.keys, {x: 3, y: 0});
		var shift2Layout = getKeyByPos(layout.keys, {x: 3, y: 0});
		Assert.equals(shift2Layout.id, layout.mappingFromGrid(shift2.id));
		Assert.same([shift2.id], layout.mappingToGrid(shift2Layout.id));

		Assert.equals(null, layout.mappingFromGrid(getKeyByPos(keyboard.keys, {x: 2, y: 0}).id));
		Assert.equals(getKeyByPos(layout.keys, {x: 1, y: 0}).id, layout.mappingFromGrid(getKeyByPos(keyboard.keys, {x: 1, y: 0}).id));

		Assert.same([], layout.mappingToGrid(getKeyByPos(layout.keys, {x: 2, y: 1}).id));
	}
}
