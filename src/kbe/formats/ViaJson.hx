package kbe.formats;

import kbe.KBLEFormat.KBLEExporter;

class ViaExporter extends KBLEExporter {
	public function new() {
		super();
		this.value = "VIA json exporter";
	}

	public override function fileName():String {
		return "via.json";
	}

	public override function getLabel(keyboard:KeyBoard, key:Key):String {
		return '${key.row},${key.column}';
	}
}
