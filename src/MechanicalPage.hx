package ;

import haxe.ui.components.Button;
import components.properties.PropertyEditor;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;

enum ToolType {
    Add;
    Remove;
    Move;
    Select;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/mechanical_page.xml"))
class MechanicalPage extends HBox {
    var keyboard:KeyBoard;
    var tool:ToolType = Select;

    public function new() {
        super();
        percentWidth = 100;
        percentHeight = 100;
        text = "Mechanical";

        cMechanical.onActiveButtonChange = onButtonChange;
        propEditor.onChange = onPropertyChange;

        bAdd.onClick = function(_) {
            tool = Add;
            addNewButton(_);
        };
    }

    public function setKeyboard(keyboard:KeyBoard) {
        this.keyboard = keyboard;
    }

    function onPropertyChange(_) {
        if (cMechanical.activeButton != null) {
            cMechanical.activeButton.refresh();
        }
        cMechanical.updateLayout();
    }

    function onButtonChange(btn:KeyButton) {
        propEditor.source = btn.key;
    }

    function addNewButton(_) {
        var id = keyboard.getNextId();
        var key = new Key(id);
        keyboard.addKey(key);
        var button = cMechanical.addKey(key);
        cMechanical.activeButton = button;
    }
}
