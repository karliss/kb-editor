package kbe.components;

import haxe.ui.util.Variant;
import haxe.ui.events.UIEvent;

class FloatEditor extends NumberEditor {
	var _value:Float = 0;

	public var number(get, set):Float;
	public var minimum:Float = 0; // TODO:clamp on change
	public var maximum:Float = 100;
	public var step:Float = 1;
	public var floatRound:Bool = false;

	override function fromText():Bool {
		var num = Std.parseFloat(input.value);
		if (Math.isFinite(num) && num >= minimum && num <= maximum) {
			if (Math.abs(num - number) > step || !Math.isFinite(number)) {
				number = num;
				return true;
			}
		}
		return false;
	}

	function clamp(v:Float):Float {
		if (!Math.isFinite(v)) {
			return minimum;
		} else if (v < minimum) {
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

	function set_number(v:Null<Float>):Float {
		if (v != null) {
			_value = clamp(v);
			if (floatRound) {
				_value = Math.fround(_value / step) * step;
			}
		} else {
			_value = Math.NaN;
		}
		showVal();
		// dispatch(new UIEvent(UIEvent.CHANGE));
		return _value;
	}

	function get_number():Float {
		return _value;
	}

	override function set_value(value:Dynamic):Dynamic {
		return number = value;
		/*switch (value) { //TODO: check this
			case Float(v):
				return number = v;
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
