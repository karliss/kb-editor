package;

import haxe.io.Bytes;
import Exporter.Importer;

class TestImporter implements Importer {
	public function new() {}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var result = new KeyBoard();
		trace(bytes.length);
		for (i in 0...bytes.length) {
			result.createKey();
		}
		return result;
	}
}
