package kbe;

import kbe.Exporter;
import haxe.io.BytesBuffer;

class TestExporter implements Exporter {
	public var value(default, null):String = "Dummy exporter";

	public function new() {}

	public function convert(keyboard:KeyBoard):haxe.io.Bytes {
		var result = new BytesBuffer();
		result.addString("1234");
		return result.getBytes();
	}
}
