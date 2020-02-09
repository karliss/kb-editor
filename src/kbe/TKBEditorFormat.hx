package kbe;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Json;
import haxe.DynamicAccess;
import kbe.KeyBoard;
import kbe.Exporter;

class TKBEImporter implements Exporter.Importer {
	public var value(default, null):String = "this KBE JSON importer [WIP]";

	public function new() {}

	private function convertKey(input:DynamicAccess<Null<Dynamic>>):Key {
		var id = input.get("id");
		if (id == null) {
			throw "Key id not specified";
		}
		var key = new Key(id);
		for (prop => value in input) {
			switch (prop) {
				case "id":
					{}
				case "name":
					key.name = value;
				case "x":
					key.x = value;
				case "y":
					key.y = value;
				case "w":
					key.width = value;
				case "h":
					key.height = value;
				case "row":
					key.row = value;
				case "col":
					key.column = value;
				default:
					trace('Warning unrecognized property $prop');
			}
		}

		return key;
	}

	private function convertKeys(input:Array<Dynamic>):Array<Key> {
		return input.map(convertKey);
	}

	private function convertLayout(input:DynamicAccess<Null<Dynamic>>):KeyboardLayout {
		var layout = new KeyboardLayout();
		for (key => value in input) {
			switch (key) {
				case "name":
					layout.name = value;
				case "keys":
					layout.keys = convertKeys(value);
				case "mapping":
					var data:Array<Array<Int>> = value;
					for (pair in data) {
						var keyboardId = pair[0];
						var layoutId = pair[1];
						layout.addMapping(keyboardId, layoutId);
					}
				case "synchronised":
					layout.synchronised = value;
				case _:
					trace('Unrecognized keyboard layout field $key');
			}
		}
		return layout;
	}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var json = Json.parse(bytes.toString());

		for (key => value in (json : DynamicAccess<Null<Dynamic>>)) {
			switch (key) {
				case "keys":
					for (key in convertKeys(value)) {
						keyboard.addKey(key);
					}
				case "layouts":
					var layouts:Array<Dynamic> = value;
					for (layout in layouts) {
						keyboard.addLayout(convertLayout(layout));
					}
				case "description":
					var description:DynamicAccess<Null<Dynamic>> = value;
					for (key => value in description) {
						keyboard.description.set(key, value == null ? "" : value);
					}
			}
		}
		return keyboard;
	}
}

class TKBEExporter implements Exporter {
	public var value(default, null):String = "this KBE exporter [WIP]";
	public var prettyPrint:Bool = false;

	public function new(defaultPrettyPrint:Bool = true) {}

	function addArray(output:Map<String, Dynamic>, name:String, input:Array<Dynamic>) {
		if (input.length > 0) {
			output.set(name, input);
		}
	}

	function exportKey(key:Key):Dynamic {
		var result:Map<String, Dynamic> = [
			"id" => key.id,
			"x" => key.x,
			"y" => key.y,
			"row" => key.row,
			"col" => key.column
		];
		if (key.name != "") {
			result.set("name", key.name);
		}
		if (key.width != 1.0) {
			result.set("w", key.width);
		}
		if (key.height != 1.0) {
			result.set("h", key.height);
		}
		if (key.angle != 0.0) {
			result.set("angle", key.angle);
		}

		return result;
	}

	function exportLayoutKey(key:Key):Dynamic {
		var result:Map<String, Dynamic> = ["id" => key.id, "x" => key.x, "y" => key.y,];
		if (key.name != "") {
			result.set("name", key.name);
		}
		if (key.width != 1.0) {
			result.set("w", key.width);
		}
		if (key.height != 1.0) {
			result.set("h", key.height);
		}

		return key;
	}

	function exportLayout(layout:KeyboardLayout):Dynamic {
		var result:Map<String, Dynamic> = ["name" => layout.name];
		if (layout.synchronised) {
			result.set("synchronised", true);
		} else {
			addArray(result, "keys", layout.keys.map(exportKey));
			var mapping = [];
			for (keyboardId => layoutId in layout.getMapping()) {
				mapping.push([keyboardId, layoutId]);
			}
			addArray(result, "mapping", mapping);
		}
		return result;
	}

	public function convertWithConfig(keyboard:KeyBoard, prettyPrint:Bool):Bytes {
		var data = new Map<String, Dynamic>();
		addArray(data, "keys", keyboard.keys.map(exportKey));
		addArray(data, "layouts", keyboard.layouts.map(exportLayout).toArray());
		if (keyboard.description.iterator().hasNext()) {
			data.set("description", keyboard.description);
		}

		return Bytes.ofString(Json.stringify(data, prettyPrint ? " " : null));
	}

	public function convert(keyboard:KeyBoard):Bytes {
		return convertWithConfig(keyboard, prettyPrint);
	}

	public function fileName():String {
		return "keyboard.json";
	}

	public function mimeType():String {
		return "text/json";
	}
}
