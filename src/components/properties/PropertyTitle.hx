package components.properties;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;

class PropertyTitle extends HBox {
    var label: Label;
    var expanded:Bool = true;
    public var onExpand:Bool->Void;

    public function new() {
        super();
        label = new Label();
        addComponent(label);
        refreshLabel();
        this.percentWidth = 100;
        this.onClick = function(_) {
            expanded = !expanded;
            refreshLabel();
            if (onExpand != null) {
                onExpand(expanded);
            }
        };
    }

    function refreshLabel() {
        label.text = (expanded ?  "-" : "+") + this.text;
    }

    override function set_text(text:String):String {
        var res = super.set_text(text);
        refreshLabel();
        return res;
    }
}
