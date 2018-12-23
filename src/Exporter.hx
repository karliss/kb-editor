package;

import haxe.io.Bytes;
import KeyBoard;

interface Exporter {
	public function convert(keyboard:KeyBoard):Bytes;
}

interface Importer {
	public function convert(bytes:Bytes, ?name:String):KeyBoard;
}

interface PartialImporter {
	public function convert(bytes:Bytes, keyboard:KeyBoard):Void;
}
