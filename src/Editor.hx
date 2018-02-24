package ;

import haxe.ui.core.Component;
import haxe.ui.components.Button;

@:build(haxe.ui.macros.ComponentMacros.build("assets/editor.xml"))
class Editor extends Component {

    public function new() {
        super();
        percentWidth = 100;
        percentHeight = 100;
        var x = new KeyButton(new Key(3));
        for (i in 0...10) {
            var bt:Button = new Button();
            bt.moveComponent(i * 50, i * 50);
            bt.width = 25;
            bt.height = 25;
            cMechanical.addComponent(bt);
        }
    }
}
