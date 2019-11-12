package;

import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Json;
import KeyBoard;
import Exporter;

// Importer exporter for Keyboard layout editor https://github.com/ijprest/keyboard-layout-editor
// http://www.keyboard-layout-editor.com/
class KBLEImporter implements Exporter.Importer {
	public function new() {}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var json:Array<Array<Dynamic>> = Json.parse(bytes.toString());
		var y:Float = 0;
		var x:Float = 0;
		var w:Float = 1;
		var h:Float = 1;
		var id = 0;
		for (line in json) {
			for (item in line) {
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
					var properties:DynamicAccess<Dynamic> = item;
					for (key => value in properties.keyValueIterator()) {
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
		}
		return keyboard;
	}
}
