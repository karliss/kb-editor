package kbe.tests;

import kbe.KeyBoard.KeyboardLayout;
import kbe.Key.Point;
import haxe.ds.HashMap;
import haxe.io.Bytes;
import utest.Assert;
import kbe.QMKLayoutMacro.QMKLayoutMacroExporter;

class QMKLayoutMacro extends utest.Test {
	function testExportEmpty() {
		var exporter = new QMKLayoutMacroExporter(true);
		var keyboard = new KeyBoard();

		Assert.equals("", exporter.convert(keyboard).toString());
	}

	function testExport1() {
		var exporter = new QMKLayoutMacroExporter(false);
		var keyboard = new KeyBoard();
		var k1 = keyboard.createAndAddKey();
		var k2 = keyboard.createAndAddKey();
		k2.x = 1;
		k2.column = 1;
		var k3 = keyboard.createAndAddKey();
		k3.x = 2;
		k3.column = 2;
		var k4 = keyboard.createAndAddKey();
		k4.y = 1;
		k4.row = 1;
		k4.column = 2;
		var layout0 = new KeyboardLayout();

		layout0.name = "layout0";
		keyboard.addLayout(layout0);
		layout0.setKeys(keyboard.keys);

		layout0.addMapping(3, -1);

		var layout2 = new KeyboardLayout();
		layout2.name = "LAY_2";
		keyboard.addLayout(layout2);
		layout2.setKeys(keyboard.keys);
		layout2.addMapping(1, 2);
		layout2.addMapping(2, 1);

		var expected1 = "#define layout0( \\
K00,K01,K02, \\
K10 \\
) {\\
    { K00,K01,KC_NO}, \\
    { KC_NO,KC_NO,K10} \\
}
";
		Assert.equals(expected1, exporter.convertLayout(keyboard, keyboard.layouts[0]).toString());

		var expected2 = "#define layout0( \\
K00,K01,K02, \\
K10 \\
) {\\
    { K00,K01,KC_NO}, \\
    { KC_NO,KC_NO,K10} \\
}
#define LAY_2( \\
K00,K01,K02, \\
K10 \\
) {\\
    { K01,K00,K02}, \\
    { KC_NO,KC_NO,K10} \\
}
";
		Assert.equals(expected2, exporter.convert(keyboard).toString());

		exporter.argName = MatrixRows;
		var expected3 = "#define layout0( \\
K00,K01, U0, \\
K12 \\
) {\\
    { K00,K01,KC_NO}, \\
    { KC_NO,KC_NO,K12} \\
}
#define LAY_2( \\
K01,K00,K02, \\
K12 \\
) {\\
    { K00,K01,K02}, \\
    { KC_NO,KC_NO,K12} \\
}
";
		Assert.equals(expected3, exporter.convert(keyboard).toString());
	}
}
