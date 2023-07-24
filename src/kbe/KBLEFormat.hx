package kbe;

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
