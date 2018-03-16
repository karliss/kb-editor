package components;

import haxe.ui.util.Variant;
import haxe.ui.core.UIEvent;

class IntegerEditor extends NumberEditor {
    var _value:Int = 0;
    public var number(get, set):Int;
    public var minimum:Int = 0; //TODO:clamp on change
    public var maximum:Int = 100;
    public var step:Int = 1;

    override function fromText() {
        var num = Std.parseInt(input.value);
        if (num >= minimum && num <= maximum) {
            number = num;
        }
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
    }

    override function onMinus(_) {
        number -= step;
    }

    function set_number(v:Int):Int {
        _value = clamp(v);
        showVal();
        dispatch(new UIEvent(UIEvent.CHANGE));
        return _value;
    }
    
    function get_number():Int {
        return _value;
    }

    override function set_value(value:Variant):Variant {
        switch(value) {
            case Float(v): return number = Math.round(v);
            case Int(v): return number = v;
            default: throw "Bad value type";
        }
    }
    
    override function get_value():Variant {
        return number;
    }
}