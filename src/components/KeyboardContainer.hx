package components;

import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Absolute;

import haxe.ui.layouts.AbsoluteLayout;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.MouseEvent;

class KeyboardContainer extends Box {
    private var scrollView:ScrollView = new ScrollView();
    private var canvas:Absolute = new Absolute();
    private var buttons:List<KeyButton> = new List<KeyButton>();

    public var activeButton(default, set):KeyButton = null;
    public var onActiveButtonChange:KeyButton->Void;

    public var scale(default, set):Int = 32;

    public function new() {
        super();
        scrollView.addComponent(canvas);
        //canvas.backgroundColor = 0x00ff00;
        var dummy = new Component(); // hack due to the way absolute gets resized
        canvas.addComponent(dummy);

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

    public function updateLayout() {
        canvas.autoSize();
    }

    public function addKey(key:Key):KeyButton {
        var button:KeyButton = new KeyButton(key);
        button.scale = scale;
        button.onClick = onKeyClick;
        addComponent(button);
        buttons.add(button);
        return button;
    }

    function set_scale(v:Int):Int {
        scale = v;
        for (button in buttons) {
            button.scale = v;
        }
        return v;
    }

    function set_activeButton(button:KeyButton):KeyButton {
        if (activeButton != null) {
            activeButton.removeClass("selected");
        }
        activeButton = button;
        activeButton.addClass("selected");
        if (onActiveButtonChange != null) {
            onActiveButtonChange(activeButton);
        }
        return button;
    }

    private function onKeyClick(e:MouseEvent) {
        activeButton = cast e.target;
    }
}
