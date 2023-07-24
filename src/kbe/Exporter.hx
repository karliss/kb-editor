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
	public var text(default, null):String;
	public function convert(bytes:Bytes, ?name:String):KeyBoard;
}

interface LayoutExporter extends Exporter {
	public var value(default, null):String;
	public function fileName():String;
	public function mimeType():String;
	public function convertLayout(keyboard:KeyBoard, currentLayout:KeyboardLayout):Bytes;
}
