package ;

import haxe.ui.core.Component;
import haxe.ui.components.Button;

@:build(haxe.ui.macros.ComponentMacros.build("assets/editor.xml"))
class Editor extends Component {
    var pageMechanical:MechanicalPage;
    var keyboard = new KeyBoard();

    public function new() {
        super();
        percentWidth = 100;
        percentHeight = 100;

        pageMechanical = new MechanicalPage();
        pageMechanical.setKeyboard(keyboard);
        tabList.addComponent(pageMechanical);
    }
}
