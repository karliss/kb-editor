package kbe;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import thx.csv.Csv;
import kbe.KeyBoard;
import kbe.Exporter;

class CSVImporter implements Exporter.Importer {
	public var value(default, null):String = "CSV importer [WIP]";

	public function new() {}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var csv = Csv.decodeObjects(bytes.toString());
		var fields = ["name", "x", "y", "angle", "width", "height", "row", "column"];
		for (line in csv) {
			var idParsed = Std.parseInt(Reflect.field(line, "id"));
			var id:Int = (idParsed != null ? idParsed : 1);
			var key = new Key(id);
			for (field in fields) {
				var value = Reflect.field(line, field);
				if (value != null) {
					if (field == "name") {
						Reflect.setField(key, field, value);
					} else {
						Reflect.setField(key, field, Std.parseFloat(value));
					}
				}
			}
			keyboard.addKey(key);
		}
		return keyboard;
	}
}

class CSVExporter implements Exporter {
	public var value(default, null):String = "CSV exporter [WIP]";

	public function new() {}

	public function convert(keyboard:KeyBoard):Bytes {
		var ans = new BytesBuffer();
		var data:Array<Array<String>> = [];
		data.push(["id", "name", "x", "y", "angle", "width", "height", "row", "column"]);
		for (key in keyboard.keys) {
			var row:Array<String> = [
				Std.string(key.id),
				key.name,
				Std.string(key.x),
				Std.string(key.y),
				Std.string(key.angle),
				Std.string(key.width),
				Std.string(key.height),
				Std.string(key.row),
				Std.string(key.column)
			];
			data.push(row);
		}
		return Bytes.ofString(Csv.encode(data));
	}

	public function fileName():String {
		return "keyboard.csv";
	}

	public function mimeType():String {
		return "text/csv";
	}
}
