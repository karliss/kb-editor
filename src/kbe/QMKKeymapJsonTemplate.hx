package kbe;

import kbe.QMKLayoutMacro.QMKLayoutMacroExporter;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import kbe.KeyBoard;
import kbe.Exporter.LayoutExporter;

class QMKKeymapJsonTemplateExporter implements LayoutExporter {
	public var value(default, null):String;

	public function new(all:Bool) {
		if (all) {
			this.value = "QMK keymap_json template all layout";
		} else {
			this.value = "QMK keymap_json template";
		}
	}

	public function fileName():String {
		return "keymap_part.json";
	}

	public function mimeType():String {
		return "text/json";
	}

	function addPadding(buffer:StringBuf, w:Int) {
		for (_ in 0...w) {
			buffer.add(" ");
		}
	}

	function printKeys(buffer:StringBuf, keys:Array<Key>, labels:Array<String>) {
		var minwidth = 1;
		for (label in labels) {
			var l = label.length + 1;
			if (l > minwidth) {
				minwidth = l;
			}
		}

		var layout_order = QMKLayoutMacro.QMKLayoutMacroExporter.calculateLayoutPos(keys);

		var lineWidth = 0;
		for (i in 0...keys.length) {
			var key = keys[i];
			var name = labels[i];
			var x = Std.int((minwidth) * key.x + 0.01);
			if (x > lineWidth) {
				var w = x - lineWidth;
				addPadding(buffer, w);
				lineWidth += w;
			}
			var paddingl = 0, paddingr = 0;
			var paddingW = Std.int(minwidth * key.width) - 1 - name.length;
			if (key.width <= 1) {
				paddingl = paddingW;
			} else {
				paddingr = Std.int(paddingW / 2);
				paddingl = paddingW - paddingr;
			}
			addPadding(buffer, paddingl);
			buffer.add(name);
			addPadding(buffer, paddingr);
			lineWidth += paddingl + paddingr + name.length + 1;
			var pos = layout_order.pos.get(keys[i]);
			if (pos == null) {
				throw "Key position not calcualted";
			}
			if (i + 1 < keys.length) {
				var nextPos = layout_order.pos.get(keys[i + 1]);
				if (nextPos == null) {
					throw "Key position not calcualted";
				}
				buffer.add(",");
				if (nextPos.row != pos.row) {
					buffer.add(' \n');
					lineWidth = 0;
				}
			} else {
				buffer.add(' \n');
			}
		}
	}

	private function convertLayoutImpl(buffer:StringBuf, keyboard:KeyBoard, layout:KeyboardLayout) {
		var layout_order = QMKLayoutMacroExporter.calculateLayoutPos(layout.keys);
		var argNames = new Map<Int, String>();
		for (key in layout_order.keys) {
			var pos = layout_order.pos.get(key);
			if (pos == null) {
				throw "Layout key position not calculated properly";
			}
			argNames.set(key.id, '"KC_NO"   ');
		}

		var minwidth = 1;
		for (id => argName in argNames) {
			var w = argName.length;
			if (w > minwidth) {
				minwidth = w;
			}
		}

		buffer.add('"layout":"${layout.name}",\n');
		buffer.add('"layers":[\n[\n');

		var keys = layout_order.keys;
		var argLabels = layout_order.keys.map(key -> {
			var result = argNames.get(key.id);
			if (result == null) {
				throw "Macro argument name missing";
			} else {
				return (result : String);
			}
		});
		printKeys(buffer, layout_order.keys, argLabels);

		buffer.add("]\n]\n");
	}

	public function convertLayout(keyboard:KeyBoard, currentLayout:KeyboardLayout):Bytes {
		var buffer = new StringBuf();
		convertLayoutImpl(buffer, keyboard, currentLayout);
		return Bytes.ofString(buffer.toString());
	}

	public function convertWithConfig(keyboard:KeyBoard):Bytes {
		var buffer = new StringBuf();
		var layouts = keyboard.layouts.toArray();
		for (layout in layouts) {
			convertLayoutImpl(buffer, keyboard, layout);
		}
		return Bytes.ofString(buffer.toString());
	}

	public function convert(keyboard:KeyBoard):Bytes {
		return convertWithConfig(keyboard);
	}
}
