package components.properties;

import haxe.ui.components.TextField;

class PropertyText extends PropertyItem {
    public function new() {
        super();
        addComponent(new TextField());
    }
}
