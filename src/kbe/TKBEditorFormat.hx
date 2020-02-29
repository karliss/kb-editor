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
			if (value == null) {
				continue;
			}
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
			if (value == null) {
				continue;
			}
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

	function convertWireMapping(input:DynamicAccess<Null<Dynamic>>):WireMapping {
		var result = new WireMapping();
		var columnData:Null<DynamicAccess<Null<Dynamic>>> = null;
		for (key => value in input) {
			if (value == null) {
				continue;
			}
			switch (key) {
				case "hasMatrixRows":
					result.hasWireColumn = value;
				case "size":
					result.resize(value);
				case "matrixRow":
					var values:Array<Int> = value;
					for (i in 0...values.length) {
						result.setMatrixRow(i, values[i]);
					}
				case "properties":
					columnData = value;
				default:
					throw 'Unsupported wire mapping property ($key)';
			}
		}
		if (columnData != null) {
			var names = result.columnNames.copy();
			for (name in names) {
				result.removeColumn(name);
			}
			var column = 0;
			for (name => values in columnData) {
				result.addColumn(name);
				var index = 0;
				if (values == null) {
					continue;
				}
				for (value in cast(values, Array<Dynamic>)) {
					result.setColumnValue(index, column, value);
					index++;
				}
				column++;
			}
		}
		return result;
	}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var json = Json.parse(bytes.toString());

		for (key => value in (json : DynamicAccess<Null<Dynamic>>)) {
			if (value == null) {
				continue;
			}
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
				case "rowMapping":
					keyboard.rowMapping = convertWireMapping(value);
				case "columnMapping":
					keyboard.columnMapping = convertWireMapping(value);
				default:
					throw 'Unexpected property $key';
			}
		}
		return keyboard;
	}
}

class TKBEExporter implements Exporter {
	public var value(default, null):String = "this KBE exporter [WIP]";
	public var prettyPrint:Bool = true;

	public function new(defaultPrettyPrint:Bool = true) {}

	function addArray(output:Dynamic, name:String, input:Array<Dynamic>) {
		if (input.length > 0) {
			Reflect.setField(output, name, input);
		}
	}

	function exportKey(key:Key):Dynamic {
		var result = {
			"id": key.id,
			"x": key.x,
			"y": key.y,
			"row": key.row,
			"col": key.column
		};
		if (key.name != "") {
			Reflect.setField(result, "name", key.name);
		}
		if (key.width != 1.0) {
			Reflect.setField(result, "w", key.width);
		}
		if (key.height != 1.0) {
			Reflect.setField(result, "h", key.height);
		}
		if (key.angle != 0.0) {
			Reflect.setField(result, "angle", key.angle);
		}

		return result;
	}

	function exportLayoutKey(key:Key):Dynamic {
		var result = {"id": key.id, "x": key.x, "y": key.y};
		if (key.name != "") {
			Reflect.setField(result, "name", key.name);
		}
		if (key.width != 1.0) {
			Reflect.setField(result, "w", key.width);
		}
		if (key.height != 1.0) {
			Reflect.setField(result, "h", key.height);
		}

		return key;
	}

	function exportLayout(layout:KeyboardLayout):Dynamic {
		var result = {"name": layout.name};
		if (layout.synchronised) {
			Reflect.setField(result, "synchronised", true);
		} else {
			addArray(result, "keys", layout.keys.map(exportKey));
			var mapping = [];
			for (keyboardId => layoutId in layout.getMapping()) {
				mapping.push([keyboardId, layoutId]);
			}
			mapping.sort((a, b) -> {
				if (a[0] != b[0]) {
					return a[0] - b[0];
				}
				return a[1] - b[1];
			});
			addArray(result, "mapping", mapping);
		}
		return result;
	}

	function convertWireMapping(mapping:WireMapping):Dynamic {
		var size = mapping.rows;
		var data = {
			"hasMatrixRows": mapping.hasWireColumn,
			"size": size
		};
		if (mapping.hasWireColumn) {
			Reflect.setField(data, "matrixRow", [for (i in 0...size) mapping.getMatrixRow(i)]);
		}
		var columnIndex = 0;
		var columnList = {};
		for (column in mapping.columnNames) {
			var columnData = [for (i in 0...size) mapping.getColumnValue(i, columnIndex)];
			var tailSize = 0;
			while (columnData.length > 0) {
				var last = columnData.pop();
				if (last != null && last != "") {
					columnData.push(last);
					break;
				}
			}
			Reflect.setField(columnList, column, columnData);
			columnIndex += 1;
		}
		if (mapping.columnNames.length > 0) {
			Reflect.setField(data, "properties", columnList);
		}
		return data;
	}

	public function convertWithConfig(keyboard:KeyBoard, prettyPrint:Bool):Bytes {
		var data = {};
		addArray(data, "keys", keyboard.keys.map(exportKey));
		addArray(data, "layouts", keyboard.layouts.map(exportLayout).toArray());
		if (keyboard.description.iterator().hasNext()) {
			Reflect.setField(data, "description", keyboard.description);
		}
		Reflect.setField(data, "rowMapping", convertWireMapping(keyboard.rowMapping));
		Reflect.setField(data, "columnMapping", convertWireMapping(keyboard.columnMapping));

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
