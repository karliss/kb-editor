package kbe;

import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import tjson.TJSON;
import kbe.KeyBoard;
import kbe.Exporter.LayoutExporter;

enum ArgName {
	LayoutRows;
	MatrixRows;
}

class QMKLayoutMacroExporter implements LayoutExporter {
	public var value(default, null):String;

	public var exportAll:Bool;
	public var argName:ArgName = LayoutRows;
	public var unmappedKey:String = "KC_NO";
	public var unexistingKey:String = "KC_NO";

	public function new(all:Bool) {
		this.exportAll = all;
		if (exportAll) {
			this.value = "QMK layout macro, all layouts";
		} else {
			this.value = "QMK layout macro";
		}
	}

	public function fileName():String {
		return "layouts.h";
	}

	public function mimeType():String {
		return "text/plain";
	}

	private function calculateLayoutPos(layout:KeyboardLayout):{
		keys:Array<Key>,
		pos:Map<Key, {row:Int, col:Int}>
	} {
		var keys = layout.keys;
		var pos = new Map<Key, {row:Int, col:Int}>();
		if (keys.length > 0) {
			var row = 0;
			var col = -1;
			var prev = keys[0];
			for (key in keys) {
				if (key.y - prev.y > 0.5) {
					row += 1;
					col = 0;
				} else if (key.x < prev.x) {
					throw 'Can\'t analyze layout key order in layout ${layout.name}';
				} else if (key.y < prev.y - 0.1) {
					throw 'Can\'t analyze layout key order in layout ${layout.name}';
				} else {
					col += 1;
				}
				pos.set(key, {row: row, col: col});
				prev = key;
			}
		}
		return {keys: keys, pos: pos};
	}

	private function convertLayout(buffer:StringBuf, keyboard:KeyBoard, layout:KeyboardLayout) {
		var layout_order = calculateLayoutPos(layout);
		var argNames = new Map<Int, String>();
		if (layout_order.keys.length > 0) {
			switch (argName) {
				case LayoutRows:
					{
						for (key in layout_order.keys) {
							var pos = layout_order.pos.get(key);
							argNames.set(key.id, 'K${StringTools.hex(pos.row)}${StringTools.hex(pos.col)}');
						}
					}
				case MatrixRows:
					{
						var umappedLayoutPos = 0;
						for (key in layout_order.keys) {
							var mapping = layout.mappingToGrid(key.id);
							if (mapping.length > 0) {
								var keyboardKey = keyboard.getKeyById(mapping[0]);
								if (keyboardKey != null) {
									var row = keyboard.getMatrixRow(keyboardKey.row);
									var col = keyboard.getMatrixRow(keyboardKey.column);
									argNames.set(key.id, 'K${StringTools.hex(row)}${StringTools.hex(col)}');
								}
							}
							if (!argNames.exists(key.id)) {
								argNames.set(key.id, 'U${umappedLayoutPos}');
								umappedLayoutPos += 1;
							}
						}
					}
			}
		}

		var minwidth = 1;
		for (id => argName in argNames) {
			var w = argName.length;
			if (w > minwidth) {
				minwidth = w;
			}
		}
		buffer.add('#define ${layout.name}( \\\n');

		var addPadding = (w:Int) -> {
			for (_ in 0...w) {
				buffer.add(" ");
			}
		};
		var keys = layout_order.keys;
		for (i in 0...keys.length) {
			var key = keys[i];
			var name = argNames.get(key.id);
			var padding = minwidth - name.length;
			var pos = layout_order.pos.get(keys[i]);
			addPadding(padding);
			buffer.add(name);
			if (i + 1 < keys.length) {
				var nextPos = layout_order.pos.get(keys[i + 1]);
				buffer.add(",");
				if (nextPos.row != pos.row) {
					buffer.add(' \\\n');
				}
			} else {
				buffer.add(' \\\n');
			}
		}
		buffer.add(") {\\\n");
		var matrixSize = keyboard.getMatrixSize();
		var matrix:Array<Array<Key>> = [for (y in 0...matrixSize.row) [for (x in 0...matrixSize.col) null]];
		for (key in keyboard.keys) {
			var pos = keyboard.getMatrixPos(key);
			var existingKey = matrix[pos.row][pos.col];
			if (existingKey != null) {
				throw 'Conflicting key matrix at row:${pos.row} col:${pos.col}';
			}
			matrix[pos.row][pos.col] = key;
		}
		for (row in 0...matrix.length) {
			buffer.add("    { ");
			for (col in 0...matrixSize.col) {
				if (col > 0) {
					buffer.add(",");
				}
				var key = matrix[row][col];
				var name = this.unmappedKey;
				if (key != null) {
					var layoutId = layout.mappingFromGrid(key.id);
					if (layoutId != null) {
						name = argNames.get(layoutId);
					} else {
						name = this.unmappedKey;
					}
				}
				addPadding(minwidth - name.length);
				buffer.add(name);
			}
			if (row != matrix.length - 1) {
				buffer.add("}, \\\n");
			} else {
				buffer.add("} \\\n");
			}
		}
		buffer.add("}\n");
	}

	public function convert(keyboard:KeyBoard, currentLayout:KeyboardLayout):Bytes {
		var buffer = new StringBuf();
		if (exportAll) {
			for (layout in keyboard.layouts) {
				convertLayout(buffer, keyboard, layout);
			}
		} else {
			convertLayout(buffer, keyboard, currentLayout);
		}
		return Bytes.ofString(buffer.toString());
	}
}
