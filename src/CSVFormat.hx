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
		var columns = [];
		for (key in keyboard.keys) {}
		return ans.getBytes();
	}
}
