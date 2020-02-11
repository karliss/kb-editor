package kbe;

import haxe.io.Bytes;
import kbe.KeyBoard;
import kbe.KeyBoard.KeyboardLayout;

interface Exporter {
	public var value(default, null):String;
	public function fileName():String;
	public function mimeType():String;
	public function convert(keyboard:KeyBoard):Bytes;
}

interface Importer {
	public var value(default, null):String;
	public function convert(bytes:Bytes, ?name:String):KeyBoard;
}

interface PartialImporter {
	public function convert(bytes:Bytes, keyboard:KeyBoard):Void;
}

interface LayoutExporter {
	public var value(default, null):String;
	public function fileName():String;
	public function mimeType():String;
	public function convert(keyboard:KeyBoard, currentLayout:KeyboardLayout):Bytes;
}
