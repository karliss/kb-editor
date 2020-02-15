package kbe.components;

import haxe.ui.events.UIEvent;
import haxe.ui.focus.IFocusable;
import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import haxe.ui.layouts.HorizontalLayout;
import haxe.ui.core.Component;

class NumberEditor extends Component implements IFocusable {
	public var focus(get, set):Bool;
	public var allowFocus(get, set):Bool;

	var input:TextField;
	var plus:Button;
	var minus:Button;

	public function new() {
		input = new TextField();
		plus = new Button();
		minus = new Button();
		super();
		layout = new HorizontalLayout();
		showVal();
	}

	override function createChildren() {
		addComponent(input);
		input.restrictChars = "-0-9.";
		input.onChange = function(_) {
			fromText();
			dispatch(new UIEvent(UIEvent.CHANGE));
		};

		addComponent(plus);
		plus.text = "+";
		plus.onClick = onPlus;
		plus.repeater = true;
		plus.repeatInterval = 150;

		addComponent(minus);
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

	function get_focus():Bool {
		return input.focus;
	}

	function set_focus(value:Bool):Bool {
		return input.focus = value;
	}

	function get_allowFocus():Bool {
		return input.focus;
	}

	function set_allowFocus(value:Bool):Bool {
		return input.focus = value;
	}
}
