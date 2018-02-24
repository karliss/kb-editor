package components;

import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;

class KeyboardContainer extends Box {
    private var scrollView:ScrollView = new ScrollView();
    private var canvas:Absolute = new Absolute();
    private var buttons:List<KeyButton> = new List<KeyButton>();

    public function new() {
        super();
        scrollView.addComponent(canvas);
        canvas.backgroundColor = 0xcccccc;
        //canvas.percentHeight = 50;
        //canvas.percentWidth = 50;
        super.addComponent(scrollView);
        scrollView.percentWidth = 100;
        scrollView.percentHeight = 100;

        scrollView.backgroundColor = 0x888888;
        scrollView.layout.autoSize();
        
        percentWidth = 100;
        percentHeight = 100;
    }
    
    override public function addComponent(child:Component):Component {
        var res:Component = canvas.addComponent(child);
        return res;
    }

    public function addKey(key:Key) {
        var button = new KeyButton(key);
        addComponent(button);
        buttons.add(button);
    }
}
