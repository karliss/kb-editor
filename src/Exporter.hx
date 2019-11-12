package;

import haxe.io.Bytes;
import KeyBoard;

interface Exporter {
	public var value(default, null):String;
	public function convert(keyboard:KeyBoard):Bytes;
}

interface Importer {
	public var value(default, null):String;
	public function convert(bytes:Bytes, ?name:String):KeyBoard;
}

interface PartialImporter {
	public function convert(bytes:Bytes, keyboard:KeyBoard):Void;
}
