package kbe.formats;

import haxe.Json;
import haxe.io.Bytes;
import kbe.KBLEFormat.KBLEExporter;

class ViaExporter extends KBLEExporter {
	public function new() {
		super();
		this.value = "VIA json exporter";
	}

	public override function fileName():String {
		return "via.json";
	}

	public override function getLabel(keyboard:KeyBoard, key:Key):String {
		return '${key.row},${key.column}';
	}

	public override function convert(keyboard:KeyBoard):Bytes {
		var data = {
			name: keyboard.description.get("keyboard_name") ?? "",
			vendorId: "",
			productId: "",
			menus: [],
			keycodes: [],
			matrix: {rows: keyboard.rowMapping.rows, cols: keyboard.columnMapping.rows},
			layouts: {
				keymap: process(keyboard)
			}
		};

		var res = Json.stringify(data, null, " ");
		return Bytes.ofString(res);
	}
}
