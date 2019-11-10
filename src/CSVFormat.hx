package;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import thx.csv.Csv;
import KeyBoard;
import Exporter;

/*
	class CSVImporter implements Exporter.Importer {
	public function convert(bytes:Bytes, ?name:String):KeyBoard {}
	}
 */
class CSVExporter implements Exporter {
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
}
