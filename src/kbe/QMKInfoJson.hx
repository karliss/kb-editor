package kbe;

import haxe.Json;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Json;
import kbe.KeyBoard;
import kbe.Exporter;

typedef ExportQMKInfoConfig = {
	prettyPrint:Bool
};

// https://beta.docs.qmk.fm/reference/reference_info_json
class QMKInfoJsonImporter implements Exporter.Importer {
	public var text(default, null):String = "QMK info.json importer";

	public function new() {}

	function chooseMainLayout(layouts:Array<KeyboardLayout>):Null<KeyboardLayout> {
		// If necesarry add some heuristics for choosing main layout
		if (layouts.length > 0) {
			return layouts[0];
		}
		return null;
	}

	function parseKeys(data:Array<Dynamic>):Array<Key> {
		var result = new Array<Key>();
		var id = 1;
		for (keyDescription in data) {
			var properties:DynamicAccess<Null<Dynamic>> = keyDescription;
			var key = new Key(id);
			id++;
			for (name => value in properties) {
				if (value == null) {
					continue;
				}
				switch (name) {
					case "label":
						key.name = value;
					case "x":
						key.x = value;
					case "y":
						key.y = value;
					case "w":
						key.width = value;
					case "h":
						key.height = value;

						// case "r":
						// case "rx":
						// case "ry":
						// case "ks":
				}
			}
			result.push(key);
		}
		return result;
	}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var json:DynamicAccess<Null<Dynamic>> = Json.parse(bytes.toString());
		var layoutResults = new Array<KeyboardLayout>();
		for (key => value in json) {
			switch (key) {
				case "layouts":
					if (value == null) {
						continue;
					}
					var layouts:DynamicAccess<Null<Dynamic>> = value;
					for (name => lprop in layouts) {
						var layout = new KeyboardLayout();
						layout.name = name;
						if (lprop == null) {
							continue;
						}
						var layoutProperties:DynamicAccess<Null<Dynamic>> = lprop;
						for (propertyName => propertyValue in layoutProperties) {
							if (propertyValue == null) {
								continue;
							}
							switch (propertyName) {
								case "layout":
									layout.keys = parseKeys(propertyValue);
								case _:
									trace('layout property ${propertyName} ignored');
							}
						}
						layoutResults.push(layout);
					}
				case _:
					keyboard.description.set(key, value == null ? "" : value);
			}
		}
		var mainLayout = chooseMainLayout(layoutResults);
		if (mainLayout != null) {
			for (key in mainLayout.keys) {
				keyboard.addKey(key.clone());
			}
			mainLayout.synchronised = true;
			mainLayout.clearMapping();
			mainLayout.keys = [];
		}
		for (layout in layoutResults) {
			if (layout != mainLayout) {
				layout.autoConnectInMode(keyboard, KeyboarLayoutAutoConnectMode.NamePos, false, 3.0);
			}
			keyboard.addLayout(layout);
		}
		return keyboard;
	}
}

class PrettyJsonPrinter extends haxe.format.JsonPrinter {}

class QMKInfoJsonExporter implements Exporter.Exporter {
	public var value(default, null):String = "QMK Info.json exporter";

	static public var DEFAULT_CONFIG:ExportQMKInfoConfig = {
		prettyPrint: false
	}

	public function new() {}

	public function fileName():String {
		return "info.json";
	}

	public function mimeType():String {
		return "text/json";
	}

	function tryAddPins(keyboard:KeyBoard, data:Dynamic) {
		// if (kkeyboard.row)
		// if (keyboard.)
		if (!(keyboard.rowMapping.columnNames.contains("pin") && keyboard.columnMapping.columnNames.contains("pin"))) {
			return;
		}
		var columnIndex = keyboard.rowMapping.getColumnIndex("pin");
		var rowPins = new Array<String>();
		var hasPin = false;
		for (i in 0...keyboard.rowMapping.rows) {
			var pin:String = keyboard.rowMapping.getColumnValue(i, columnIndex);
			if (pin != null && pin.length > 0) {
				hasPin = true;
			}
			rowPins.push(pin);
		}
		columnIndex = keyboard.columnMapping.getColumnIndex("pin");
		var columnPins = new Array<String>();
		for (i in 0...keyboard.columnMapping.rows) {
			var pin:String = keyboard.columnMapping.getColumnValue(i, columnIndex);
			if (pin != null && pin.length > 0) {
				hasPin = true;
			}
			columnPins.push(pin);
		}
		if (!hasPin) {
			return;
		}
		data.matrix_pins = {
			cols: columnPins,
			rows: rowPins
		};
	}

	function convertLayout(keyboard:KeyBoard, layout:KeyboardLayout, out:Dynamic) {
		var content:Dynamic = {};
		var keys = [];
		for (layoutKey in layout.keys) {
			var keyboardId = layout.mappingToGrid(layoutKey.id);
			var keyboardKey = keyboardId.length > 0 ? keyboard.getKeyById(keyboardId[0]) : null;
			var key:Dynamic = {};
			key.x = layoutKey.x;
			key.y = layoutKey.y;
			var EPS = 0.01;
			// TODO: odd shape handling
			if (Math.abs(layoutKey.width - 1.0) > EPS) {
				key.w = layoutKey.width;
			}
			if (Math.abs(layoutKey.height - 1.0) > EPS) {
				key.h = layoutKey.height;
			}
			if (layoutKey.name != null && layoutKey.name.length > 0) {
				key.label = layoutKey.name;
			}
			if (keyboardKey != null) {
				var pos = keyboard.getMatrixPos(keyboardKey);
				key.matrix = [pos.row, pos.col];
			}
			keys.push(key);
		}
		content.layout = keys;

		Reflect.setField(out, layout.name, content);
	}

	public function exportWithConfig(keyboard:KeyBoard, config:ExportQMKInfoConfig):Bytes {
		var data:Dynamic = {};
		tryAddPins(keyboard, data);
		var layoutG:Dynamic = {}
		for (layout in keyboard.layouts) {
			convertLayout(keyboard, layout, layoutG);
		}
		data.layouts = layoutG;

		// Reflect.setField(data, "description", keyboard.description);
		var jsonText = if (config.prettyPrint) {
			Json.stringify(data, " ");
		} else {
			Json.stringify(data);
		};
		return Bytes.ofString(jsonText);
	}

	public function convert(keyboard:KeyBoard):Bytes {
		return exportWithConfig(keyboard, DEFAULT_CONFIG);
	}
}
