package kbe;

import haxe.io.Bytes;
import kbe.KeyBoard;
import thx.color.Hsv;
import haxe.ui.util.Color;

class KeyVisualizer {
	public static function getIndexedColor(index:Int, selected:Bool):Int {
		var angle = (129.0 * index) % 360.0;
		var color = Hsv.fromFloats([angle, 0.4, 0.8]).toRgb();
		if (selected) {
			color = color.darker(0.3);
		}
		return color.toInt();
	}
}
