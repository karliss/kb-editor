package kbe;

import haxe.io.Bytes;
import kbe.KeyBoard;
import haxe.ui.util.ColorUtil;
import haxe.ui.util.Color;

enum KeyLabelMode {
	Name;
	RowColumn;
	Row;
	Column;
	LogicRowColumn;
	Id;
}

class KeyVisualizer {
	public static function getIndexedColor(index:Int, selected:Bool):Color {
		var angle = (129.0 * index) % 360.0;
		var color = ColorUtil.fromHSL(angle, 0.4, 0.8);
		if (selected) {
			color = ColorUtil.fromHSL(angle, 0.4, 0.8 - 0.3);
		}
		return color.toInt();
	}

	public static function updateButtonLabel(keyboard:KeyBoard, button:KeyButton, mode:Null<KeyLabelMode>) {
		var key = button.key;
		button.text = switch (mode) {
			case Name: key.name;
			case RowColumn: '${StringTools.hex(key.row)} ${StringTools.hex(key.column)}';
			case Row: '${key.row}';
			case Column: '${key.column}';
			case LogicRowColumn: '${StringTools.hex(keyboard.getMatrixRow(key.row))} ${StringTools.hex(keyboard.getMatrixCol(key.column))}';
			case Id: '${key.id}';
			default: '';
		};
	}

	public static var COMMON_LABEL_MODES = [
		{text: "Name", mode: KeyLabelMode.Name},
		{text: "Row column", mode: KeyLabelMode.RowColumn},
		{text: "Row", mode: KeyLabelMode.Row},
		{text: "Column", mode: KeyLabelMode.Column},
		{text: "Logic row column", mode: KeyLabelMode.LogicRowColumn},
		{text: "Id", mode: KeyLabelMode.Id},
	];
}
