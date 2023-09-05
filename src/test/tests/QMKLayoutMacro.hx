package kbe.tests;

import kbe.KeyBoard.KeyboardLayout;
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
    {   K00,  K01,KC_NO}, \\
    { KC_NO,KC_NO,  K10} \\
}
";
		Assert.equals(expected1, exporter.convertLayout(keyboard, keyboard.layouts[0]).toString());

		var expected2 = "#define layout0( \\
K00,K01,K02, \\
K10 \\
) {\\
    {   K00,  K01,KC_NO}, \\
    { KC_NO,KC_NO,  K10} \\
}
#define LAY_2( \\
K00,K01,K02, \\
K10 \\
) {\\
    {   K01,  K00,  K02}, \\
    { KC_NO,KC_NO,  K10} \\
}
";
		Assert.equals(expected2, exporter.convert(keyboard).toString());

		var config = Reflect.copy(QMKLayoutMacroExporter.DEFAULT_CONFIG);
		config.argName = MatrixRows;
		var expected3 = "#define layout0( \\
K00,K01, U0, \\
K12 \\
) {\\
    {   K00,  K01,KC_NO}, \\
    { KC_NO,KC_NO,  K12} \\
}
#define LAY_2( \\
K01,K00,K02, \\
K12 \\
) {\\
    {   K00,  K01,  K02}, \\
    { KC_NO,KC_NO,  K12} \\
}
";
		Assert.equals(expected3, exporter.convertWithConfig(keyboard, config).toString());
	}

	function testBigEnter() {
		var exporter = new QMKLayoutMacroExporter(false);
		var keyboard = new KeyBoard();
		var k1 = keyboard.createAndAddKey();
		var k4 = keyboard.createAndAddKey();
		k4.x = 2;
		k4.column = 2;
		var k2 = keyboard.createAndAddKey();
		k2.y = 1;
		k2.row = 1;
		var k3 = keyboard.createAndAddKey();
		k3.x = 1;
		k3.column = 1;
		k3.height = 2;
		var k5 = keyboard.createAndAddKey();
		k5.row = 1;
		k5.column = 2;
		k5.y = 1;
		k5.x = 2;

		var layout0 = new KeyboardLayout();
		layout0.synchronised = true;
		layout0.name = "layout0";
		keyboard.addLayout(layout0);

		var expected1 = "#define layout0( \\
K00,K01,K02, \\
K10,    K11 \\
) {\\
    {   K00,  K01,  K02}, \\
    {   K10,KC_NO,  K11} \\
}
";
		Assert.equals(expected1, exporter.convertLayout(keyboard, keyboard.layouts[0]).toString());
	}

	function testSpace() {
		var exporter = new QMKLayoutMacroExporter(false);
		var keyboard = new KeyBoard();
		for (i in 0...11) {
			var key = keyboard.createAndAddKey();
			key.x = i;
			if (i > 0) {
				key.x += 1;
			}
			key.column = i;
		}
		var key1 = keyboard.createAndAddKey();
		key1.y = 1;
		key1.row = 1;
		var key2 = keyboard.createAndAddKey();
		key2.y = 1;
		key2.x = 2;
		key2.row = 1;
		key2.width = 8;
		key2.column = 1;
		var key3 = keyboard.createAndAddKey();
		key3.x = 10;
		key3.y = 1;
		key3.row = 1;
		key3.column = 2;
		var key4 = keyboard.createAndAddKey();
		key4.x = 11;
		key4.y = 1;
		key4.row = 1;
		key4.column = 3;

		var layout0 = new KeyboardLayout();
		layout0.synchronised = true;
		layout0.name = "layout0";
		keyboard.addLayout(layout0);

		var expected1 = "#define layout0( \\
K00,    K01,K02,K03,K04,K05,K06,K07,K08,K09,K0A, \\
K10,                  K11              ,K12,K13 \\
) {\\
    {   K00,  K01,  K02,  K03,  K04,  K05,  K06,  K07,  K08,  K09,  K0A}, \\
    {   K10,  K11,  K12,  K13,KC_NO,KC_NO,KC_NO,KC_NO,KC_NO,KC_NO,KC_NO} \\
}
";
		Assert.equals(expected1, exporter.convertLayout(keyboard, keyboard.layouts[0]).toString());
	}
}
