package kbe.components;

import haxe.ui.util.Variant;
import haxe.ui.events.UIEvent;

class IntegerEditor extends NumberEditor {
	var _value:Int = 0;

	public var number(get, set):Int;
	public var minimum:Int = 0; // TODO:clamp on change
	public var maximum:Int = 100;
	public var step:Int = 1;

	override function fromText():Bool {
		var num = Std.parseInt(input.value);
		if (num != null && num >= minimum && num <= maximum) {
			if (number != num) {
				number = num;
				return true;
			}
		}
		return false;
	}

	function clamp(v:Int):Int {
		if (v < minimum) {
			return minimum;
		} else if (v > maximum) {
			return maximum;
		}
		return v;
	}

	override function onPlus(_) {
		number += step;
		dispatch(new UIEvent(UIEvent.CHANGE));
	}

	override function onMinus(_) {
		number -= step;
		dispatch(new UIEvent(UIEvent.CHANGE));
	}

	function set_number(v:Int):Int {
		_value = clamp(v);
		showVal();
		// dispatch(new UIEvent(UIEvent.CHANGE));
		return _value;
	}

	function get_number():Int {
		return _value;
	}

	override function set_value(value:Dynamic):Dynamic {
		return number = value;
		/*switch (value) { //TODO: make sure this works
			case Float(v):
				return number = Math.round(v);
			case Int(v):
				return number = v;
			default:
				throw "Bad value type";
		}*/
	}

	override function get_value():Dynamic {
		return number;
	}
}
