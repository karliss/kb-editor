package kbe;

import haxe.Json;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import tjson.TJSON;
import kbe.KeyBoard;
import kbe.Exporter;

// Importer exporter for Keyboard layout editor https://github.com/ijprest/keyboard-layout-editor
// http://www.keyboard-layout-editor.com/
class KBLEImporter implements Exporter.Importer {
	public var text(default, null):String = "Keyboard layout editor .json importer";

	public function new() {}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var json:Array<Dynamic> = TJSON.parse(bytes.toString());
		var y:Float = 0;
		var x:Float = 0;
		var w:Float = 1;
		var h:Float = 1;
		var id = 1;
		for (line in json) {
			if (Std.is(line, Array)) {
				var lineArray:Array<Dynamic> = line;
				for (item in lineArray) {
					if (Std.is(item, String)) {
						var key = new Key(id++);
						key.x = x;
						key.y = y;
						key.name = item;
						key.width = w;
						key.height = h;
						keyboard.addKey(key);
						x += w;
						w = 1;
						h = 1;
					} else {
						var properties:DynamicAccess<Null<Dynamic>> = item;
						for (key => value in properties.keyValueIterator()) {
							if (value == null) {
								continue;
							}
							switch (key) {
								case "x":
									x += value;
								case "y":
									y += value;
								case "w":
									w = value;
								case "h":
									h = value;
								case _:
									trace('Unrecognized property $key');
							}
						}
					}
				}
				y += 1;
				x = 0;
			} else {
				var description:DynamicAccess<Null<Dynamic>> = line;
				for (key => value in description) {
					keyboard.description.set(key, value == null ? "" : value);
				}
			}
		}
		return keyboard;
	}
}

class KBLERawImporter extends KBLEImporter {
	// public var value(default, null):String = "Keyboard layout editor .json importer";
	public function new() {
		super();
		this.text = "Raw layout.json";
	}

	override public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var data = new BytesBuffer();
		data.addString('[');
		data.add(bytes);
		data.addString(']');
		return super.convert(data.getBytes(), name);
	}
}

class KBLEExporter implements Exporter {
	public var value(default, null):String = "KBLE exporter";

	public function new() {}

	public function fileName():String {
		return "kble.json";
	}

	public function mimeType():String {
		return "text/json";
	}

	public function getLabel(keyboard:KeyBoard, key:Key):String {
		return key.name;
	}

	public function process(keyboard:KeyBoard):Dynamic {
		var data = [];
		var keys_sorted = keyboard.keys.copy();
		function compareFloat(a:Float, b:Float) {
			var EPS = 0.01;
			if (a < b - EPS) {
				return -1;
			} else if (a > b + EPS) {
				return 1;
			}
			return 0;
		}
		keys_sorted.sort((a, b) -> {
			var cmpy = compareFloat(a.y, b.y);
			if (cmpy != 0) {
				return cmpy;
			}
			return compareFloat(a.x, b.x);
		});
		var lastX:Float = -100;
		var lastY:Float = -100;
		var row = null;

		for (keyboardKey in keys_sorted) {
			var config:Dynamic = {};
			if (compareFloat(lastY, keyboardKey.y) != 0) {
				var difY = keyboardKey.y - lastY - 1;
				if (compareFloat(difY, 0) != 0 && row != null) {
					Reflect.setField(config, "y", difY);
				}
				row = [];
				data.push(row);
				lastY = keyboardKey.y;
				lastX = 0;
			}
			if (compareFloat(keyboardKey.x, lastX) != 0) {
				Reflect.setField(config, "x", keyboardKey.x - lastX);
			}
			var EPS = 0.01;
			// TODO: odd shape handling
			if (Math.abs(keyboardKey.width - 1.0) > EPS) {
				config.w = keyboardKey.width;
			}
			if (Math.abs(keyboardKey.height - 1.0) > EPS) {
				config.h = keyboardKey.height;
			}
			if (Reflect.fields(config).length > 0) {
				row.push(config);
			}
			row.push(getLabel(keyboard, keyboardKey));
			lastX = lastX + keyboardKey.width;
		}
		return data;
	}

	public function convert(keyboard:KeyBoard):Bytes {
		var data = process(keyboard);
		var res = Json.stringify(data);
		return Bytes.ofString(res);
	}
}
