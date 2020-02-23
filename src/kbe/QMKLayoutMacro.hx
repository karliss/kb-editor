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

typedef ExportLayoutConfig = {
	layouts:Array<KeyboardLayout>,
	unmappedKey:String,
	argName:ArgName
};

class QMKLayoutMacroExporter implements LayoutExporter {
	public var value(default, null):String;

	static public var DEFAULT_CONFIG:ExportLayoutConfig = {
		layouts: null,
		unmappedKey: "KC_NO",
		argName: LayoutRows
	};

	public function new(all:Bool) {
		if (all) {
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

	private function calculateLayoutPos(keys:Array<Key>):{
		keys:Array<Key>,
		pos:Map<Key, {row:Int, col:Int}>
	} {
		var keys = keys.copy();

		function compareFloat(a:Float, b:Float) {
			var EPS = 0.01;
			if (a < b - EPS) {
				return -1;
			} else if (a > b + EPS) {
				return 1;
			}
			return 0;
		}
		keys.sort((a, b) -> {
			var cmpy = compareFloat(a.y, b.y);
			if (cmpy != 0) {
				return cmpy;
			}
			return compareFloat(a.x, b.x);
		});

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
					throw 'Can\'t analyze layout key order';
				} else if (key.y < prev.y - 0.1) {
					throw 'Can\'t analyze layout key order';
				} else {
					col += 1;
				}
				pos.set(key, {row: row, col: col});
				prev = key;
			}
		}
		return {keys: keys, pos: pos};
	}

	function addPadding(buffer:StringBuf, w:Int) {
		for (_ in 0...w) {
			buffer.add(" ");
		}
	}

	function printMacroArgs(buffer:StringBuf, keys:Array<Key>, labels:Array<String>) {
		var minwidth = 1;
		for (label in labels) {
			var l = label.length + 1;
			if (l > minwidth) {
				minwidth = l;
			}
		}

		var layout_order = calculateLayoutPos(keys);

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
			if (i + 1 < keys.length) {
				var nextPos = layout_order.pos.get(keys[i + 1]);
				buffer.add(",");
				if (nextPos.row != pos.row) {
					buffer.add(' \\\n');
					lineWidth = 0;
				}
			} else {
				buffer.add(' \\\n');
			}
		}
	}

	private function convertLayoutImpl(buffer:StringBuf, keyboard:KeyBoard, layout:KeyboardLayout, config:ExportLayoutConfig) {
		var layout_order = calculateLayoutPos(layout.keys);
		var argNames = new Map<Int, String>();
		if (layout_order.keys.length > 0) {
			switch (config.argName) {
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

		var keys = layout_order.keys;
		var argLabels = layout_order.keys.map(key -> {
			argNames.get(key.id);
		});
		printMacroArgs(buffer, layout_order.keys, argLabels);
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

		var hasUnmapped = false;
		for (row in matrix) {
			for (v in row) {
				if (v == null) {
					hasUnmapped = true;
				}
			}
		}
		if (hasUnmapped) {
			if (minwidth < config.unmappedKey.length) {
				minwidth = config.unmappedKey.length;
			}
		}

		for (row in 0...matrix.length) {
			buffer.add("    { ");
			for (col in 0...matrixSize.col) {
				if (col > 0) {
					buffer.add(",");
				}
				var key = matrix[row][col];
				var name = config.unmappedKey;
				if (key != null) {
					var layoutId = layout.mappingFromGrid(key.id);
					if (layoutId != null) {
						name = argNames.get(layoutId);
					} else {
						name = config.unmappedKey;
					}
				}
				addPadding(buffer, minwidth - name.length);
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

	public function convertLayout(keyboard:KeyBoard, currentLayout:KeyboardLayout):Bytes {
		var buffer = new StringBuf();
		convertLayoutImpl(buffer, keyboard, currentLayout, DEFAULT_CONFIG);
		return Bytes.ofString(buffer.toString());
	}

	public function convertWithConfig(keyboard:KeyBoard, config:ExportLayoutConfig):Bytes {
		var buffer = new StringBuf();
		var layouts = config.layouts;
		if (layouts == null) {
			layouts = keyboard.layouts.toArray();
		}
		for (layout in layouts) {
			convertLayoutImpl(buffer, keyboard, layout, config);
		}
		return Bytes.ofString(buffer.toString());
	}

	public function convert(keyboard:KeyBoard):Bytes {
		return convertWithConfig(keyboard, DEFAULT_CONFIG);
	}
}
