package kbe;

import haxe.io.Bytes;
import kbe.KeyBoard;
import thx.color.Hsv;
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
	public static function getIndexedColor(index:Int, selected:Bool):Int {
		var angle = (129.0 * index) % 360.0;
		var color = Hsv.fromFloats([angle, 0.4, 0.8]).toRgb();
		if (selected) {
			color = color.darker(0.3);
		}
		return color.toInt();
	}

	public static function updateButtonLabel(keyboard:KeyBoard, button:KeyButton, mode:KeyLabelMode) {
		var key = button.key;
		button.text = switch (mode) {
			case Name: key.name;
			case RowColumn: '${StringTools.hex(key.row)} ${StringTools.hex(key.column)}';
			case Row: '${key.row}';
			case Column: '${key.column}';
			case LogicRowColumn: '${StringTools.hex(keyboard.getMatrixRow(key.row))} ${StringTools.hex(keyboard.getMatrixCol(key.column))}';
			case Id: '${key.id}';
		};
	}

	public static var COMMON_LABEL_MODES = [
		{value: "Name", mode: KeyLabelMode.Name},
		{value: "Row column", mode: KeyLabelMode.RowColumn},
		{value: "Row", mode: KeyLabelMode.Row},
		{value: "Column", mode: KeyLabelMode.Column},
		{value: "Logic row column", mode: KeyLabelMode.LogicRowColumn},
		{value: "Id", mode: KeyLabelMode.Id},
	];
}
