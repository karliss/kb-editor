package components.properties;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;

class PropertyItem extends HBox {
    var label: Label;
    var editor: haxe.ui.core.Component = null;

    public function new() {
        super();
        var label = new Label();
        addComponent(label);
        this.label = label;
        label.percentWidth = 50;
        this.percentWidth = 100;
    }

    override function get_text():String {
        return label.text;
    }

    override function addComponent(child:Component):Component {
        if (label == null) {
            return super.addComponent(child);
        }
        super.addComponent(child);
        editor = child;
        editor.percentWidth = 50;
        return child;
    }

    override function set_text(text:String):String {
        return label.text = text;
    }
}
