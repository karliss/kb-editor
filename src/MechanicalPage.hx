package ;

import haxe.ui.components.Button;
import components.properties.PropertyEditor;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/mechanical_page.xml"))
class MechanicalPage extends HBox {
    var keyboard:KeyBoard;

    public function new() {
        super();
        percentWidth = 100;
        percentHeight = 100;
        text = "Mechanical";

        cMechanical.onActiveButtonChange = onButtonChange;
        propEditor.onChange = onPropertyChange;

        bAdd.onClick = addNewButton;
    }

    public function setKeyboard(keyboard:KeyBoard) {
        this.keyboard = keyboard;
    }

    function onPropertyChange(_) {
        if (cMechanical.activeButton != null) {
            cMechanical.activeButton.refresh();
        }
    }

    function onButtonChange(btn:KeyButton) {
        propEditor.source = btn.key;
    }

    function addNewButton(_) {
        var id = keyboard.getNextId();
        var key = new Key(id);
        keyboard.addKey(key);
        cMechanical.addKey(key);
    }
}
