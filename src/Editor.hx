package ;

import haxe.ui.core.Component;
import haxe.ui.components.Button;
import components.properties.PropertyEditor;

@:build(haxe.ui.macros.ComponentMacros.build("assets/editor.xml"))
class Editor extends Component {

    public function new() {
        super();
        percentWidth = 100;
        percentHeight = 100;
        for (i in 0...10) {
            var key:Key = new Key(i);
            key.x = 50 * i;
            key.y = 50 * i;
            key.name = "$i";
            cMechanical.addKey(key);
        }
        cMechanical.onActiveButtonChange = onButtonChange;
        propEditor.onChange = onPropertyChange;
    }

    function onPropertyChange(_) {
        if (cMechanical.activeButton != null) {
            cMechanical.activeButton.refresh();
        }
    }

    function onButtonChange(btn:KeyButton) {
        propEditor.source = btn.key;
    }
}
