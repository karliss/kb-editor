package kbe;

import haxe.io.Bytes;
import kbe.KeyBoard;

interface Exporter {
	public var value(default, null):String;
	public function convert(keyboard:KeyBoard):Bytes;
	public function fileName():String;
	public function mimeType():String;
}

interface Importer {
	public var value(default, null):String;
	public function convert(bytes:Bytes, ?name:String):KeyBoard;
}

interface PartialImporter {
	public function convert(bytes:Bytes, keyboard:KeyBoard):Void;
}
