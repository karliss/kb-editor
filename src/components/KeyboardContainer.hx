package components;

import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.MouseEvent;

class KeyboardContainer extends Box {
    private var scrollView:ScrollView = new ScrollView();
    private var canvas:Absolute = new Absolute();
    private var buttons:List<KeyButton> = new List<KeyButton>();

    public var activeButton:KeyButton = null;

    public function new() {
        super();
        scrollView.addComponent(canvas);
        scrollView.backgroundColor = 0xcccccc;
        super.addComponent(scrollView);
        scrollView.percentWidth = 100;
        scrollView.percentHeight = 100;

        scrollView.layout.autoSize();

        percentWidth = 100;
        percentHeight = 100;
    }
    
    override public function addComponent(child:Component):Component {
        var res:Component = canvas.addComponent(child);
        return res;
    }

    public function addKey(key:Key):KeyButton {
        var button:KeyButton = new KeyButton(key);
        button.onClick = onKeyClick;
        addComponent(button);
        buttons.add(button);
        return button;
    }

    private function onKeyClick(e:MouseEvent) {
        if (activeButton != null) {
            activeButton.removeClass("selected");
        }
        activeButton = cast e.target;
        activeButton.addClass("selected");
    }
}
