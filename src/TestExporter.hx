package;

import Exporter;
import haxe.io.BytesBuffer;

class TestExporter implements Exporter {
	public function new() {}

	public function convert(keyboard:KeyBoard):haxe.io.Bytes {
		var result = new BytesBuffer();
		result.addString("1234");
		return result.getBytes();
	}
}