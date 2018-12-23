package components;

import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import haxe.ui.layouts.HorizontalLayout;
import haxe.ui.core.Component;

class NumberEditor extends Component {
	var input:TextField;
	var plus:Button;
	var minus:Button;

	function new() {
		super();
		layout = new HorizontalLayout();
		showVal();
	}

	override function createChildren() {
		input = new TextField();
		addComponent(input);
		input.restrictChars = "-0-9.";
		input.onChange = function(_) {
			fromText();
		};

		addComponent(plus = new Button());
		plus.text = "+";
		plus.onClick = onPlus;
		plus.repeater = true;
		plus.repeatInterval = 150;

		addComponent(minus = new Button());
		minus.text = "-";
		minus.onClick = onMinus;
		minus.repeater = true;
		minus.repeatInterval = 150;

		input.percentWidth = 100;
	}

	function fromText() {
		throw "Not implemented!";
	}

	function showVal() {
		input.text = Std.string(value);
	}

	function onPlus(_) {
		throw "Not implemented!";
	}

	function onMinus(_) {
		throw "Not implemented!";
	}
}
