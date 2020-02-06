package kbe;

import haxe.Json;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Json;
import kbe.KeyBoard;
import kbe.Exporter;

// https://beta.docs.qmk.fm/reference/reference_info_json
class QMKInfoJsonImporter implements Exporter.Importer {
	public var value(default, null):String = "QMK info.json importer";

	public function new() {}

	function chooseMainLayout(layouts:Array<KeyboardLayout>):KeyboardLayout {
		// If necesarry add some heuristics for choosing main layout
		if (layouts.length > 0) {
			return layouts[0];
		}
		return null;
	}

	function parseKeys(data:Array<Dynamic>):Array<Key> {
		var result = new Array<Key>();
		var id = 1;
		for (keyDescription in data) {
			var properties:DynamicAccess<Null<Dynamic>> = keyDescription;
			var key = new Key(id);
			id++;
			for (name => value in properties) {
				switch (name) {
					case "label":
						key.name = value;
					case "x":
						key.x = value;
					case "y":
						key.y = value;
					case "w":
						key.width = value;
					case "h":
						key.height = value;

						// case "r":
						// case "rx":
						// case "ry":
						// case "ks":
				}
			}
			result.push(key);
		}
		return result;
	}

	public function convert(bytes:Bytes, ?name:String):KeyBoard {
		var keyboard = new KeyBoard();
		var json:DynamicAccess<Null<Dynamic>> = Json.parse(bytes.toString());
		for (key => value in json) {
			switch (key) {
				case "layouts":
					var layouts:DynamicAccess<Null<Dynamic>> = value;
					for (name => lprop in layouts) {
						var layout = new KeyboardLayout();
						layout.name = name;
						var layoutProperties:DynamicAccess<Null<Dynamic>> = lprop;
						for (propertyName => propertyValue in layoutProperties) {
							switch (propertyName) {
								case "layout":
									layout.keys = parseKeys(propertyValue);
								case _:
									trace(propertyName);
							}
						}
						keyboard.layouts.push(layout);
					}
				case _:
					keyboard.description.set(key, value == null ? "" : value);
			}
		}
		var mainLayout = chooseMainLayout(keyboard.layouts);
		if (mainLayout != null) {
			for (key in mainLayout.keys) {
				keyboard.addKey(key.clone());
			}
		}
		for (layout in keyboard.layouts) {
			if (layout == mainLayout) {
				layout.connectByPos(keyboard);
			} else {
				layout.autoConnectInMode(keyboard, KeyboarLayoutAutoConnectMode.NamePos, false, 3.0);
			}
		}
		return keyboard;
	}
}
