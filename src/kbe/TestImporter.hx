package kbe;

import haxe.io.Bytes;
import kbe.Exporter.Importer;

class TestImporter implements Importer {
	public var text(default, null):String = "Dummy importer";

	public function new() {}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var result = new KeyBoard();
		trace(bytes.length);
		for (i in 0...bytes.length) {
			result.createAndAddKey();
		}
		return result;
	}
}
