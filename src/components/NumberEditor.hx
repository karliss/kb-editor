package components;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.layouts.HorizontalLayout;

class NumberEditor extends InteractiveComponent {
    var input:TextField;
    var plus:Button;
    var minus:Button;

    var _value:Float = 0;
    public var number(get, set):Float;
    public var minimum:Float = 0; //TODO:clamp on change
    public var maximum:Float = 100;
    public var step:Float = 1;

    function new() {
        super();
        layout = new HorizontalLayout();
        showVal();
    }

    override function createChildren(){
        input = new TextField();
        addComponent(input);
        input.restrictChars = "-0-9.";
        input.onChange = function(_) { fromText(); };

        addComponent(plus = new Button());
        plus.text = "+";
        plus.onClick = onPlus;

        addComponent(minus = new Button());
        minus.text = "-";
        minus.onClick = onMinus;
        
        //plus.percentWidth = 10;
        //minus.percentWidth = 10;
        input.percentWidth = 100;
    }

    function fromText() {
        var num = Std.parseFloat(input.value);
        if (Math.isFinite(num) && num >= minimum && num <= maximum) {
            _value = num;
        }
    }

    function showVal() {
        input.text = Std.string(number);
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

    function onPlus(_) {
        number += step;
    }

    function onMinus(_) {
        number -= step;
    }
    
    function set_number(v:Float):Float {
        _value = clamp(v);
        showVal();
        return _value;
    }
    
    function get_number():Float {
        return _value;
    }
}