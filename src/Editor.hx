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
            var key:Key = new Key(i);
            key.x = 50 * i;
            key.y = 50 * i;
            key.name = "$i";
            //var bt:KeyButton = new KeyButton(key);
            //var bt:Button = new Button();
            var a = cMechanical.addKey(key);
            /*bt.moveComponent(i * 50, i * 50);
            bt.width = 25;
            bt.height = 25;*/
            //cMechanical.addComponent(bt);
        }
    }
}
