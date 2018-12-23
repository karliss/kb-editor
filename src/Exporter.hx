package;

import haxe.io.Bytes;
import KeyBoard;

interface Exporter {
	public function convert(keyboard:KeyBoard):Bytes;
}

interface Importer {
	public function convert(bytes:Bytes):KeyBoard;
}

interface PartialImporter {
	public function convert(bytes:Bytes, keyboard:KeyBoard):Void;
}
