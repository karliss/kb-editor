package kbe;

import haxe.ui.util.Color;
import haxe.ui.util.ColorUtil;

class ColorExtensions {
	static public function darker(color:Color, value:Float):Color {
		var hsl = ColorUtil.toHSL(color);
		hsl.l = Math.max(0, Math.min(1, hsl.l - value));
		return ColorUtil.fromHSL(hsl.h, hsl.s, hsl.l);
	}
}
