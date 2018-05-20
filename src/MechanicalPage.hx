package ;

import components.properties.PropertyEditor;
import haxe.ui.containers.HBox;
import components.OneWayButton;
import haxe.ui.core.MouseEvent;
import components.KeyboardContainer;
import components.KeyboardContainer.KeyButtonEvent;
import haxe.ui.core.UIEvent;

enum ToolType {
    Add;
    Remove;
    Move;
    Select;
}

class Tool {
    public var page:MechanicalPage;
    public function new(p:MechanicalPage) {
        page = p;
    }
    public function activate() {
    }
    public function deactivate() {
    }
}

class AddTool extends Tool {
    function doAdd(e:MouseEvent) {
        var btn = page.addNewButton(null);
        var key = btn.key;
        var field = page.cMechanical;
        var scale:Float = page.cMechanical.scale;
        var x = (e.screenX - field.screenLeft) / scale;
        var y = (e.screenY - field.screenTop) / scale; //TODO:correct offset
        //TODO:stick to grid
        key.x = x;
        key.y = y;
        btn.refresh();
        page.propEditor.source = key;
    }
    override function activate() {
        page.cMechanical.registerEvent(MouseEvent.CLICK, doAdd);
    }
    override function deactivate() {
        page.cMechanical.unregisterEvent(MouseEvent.CLICK, doAdd);
    }
}

class RemoveTool extends Tool {
    //TODO:implement
}

class SelectTool extends Tool {
    //TODO:implement
}

class MoveTool extends Tool {
    //TODO:implement
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/mechanical_page.xml"))
class MechanicalPage extends HBox {
    var keyboard:KeyBoard;
    var tool:ToolType = Select;

    var tools:Map<ToolType, Tool>;
    var toolButtons:Map<ToolType, OneWayButton>;

    var currentTool:Tool = null;
    var currentToolBtn:OneWayButton = null;

    public function new() {
        super();
        percentWidth = 100;
        percentHeight = 100;
        text = "Mechanical";

        cMechanical.registerEvent(KeyboardContainer.BUTTON_CHANGED, onButtonChange);
        propEditor.onChange = onPropertyChange;

        bAdd.onClick = function(_) {
            tool = Add;
            addNewButton(_);
        };

        tools = createTools();
        bindToolButtons();
    }

    function createTools():Map<ToolType, Tool> {
        var result:Map<ToolType, Tool> = [
            Add => new AddTool(this),
            Remove => new RemoveTool(this),
            Move => new MoveTool(this),
            Select => new SelectTool(this),
        ];

        return result;
    }

    function selectTool(type:ToolType) {
        var tool = tools.get(type);
        var btn = toolButtons.get(type);
        if (tool == currentTool) {
            return;
        }
        if (currentTool != null) {
            currentTool.deactivate();
            currentToolBtn.selected = false;
        }
        currentTool = tool;
        currentToolBtn = btn;
        currentTool.activate();
        btn.selected = true;
    }

    function bindToolButtons() {
        toolButtons = [
            Add => bAdd,
            Remove => bRemove,
            Move => bMove,
            Select => bSelect
        ];
        for (toolType in toolButtons.keys()) {
            var button = toolButtons.get(toolType);
            button.onClick = function(_) {
                selectTool(toolType);
            };
        }
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

    function onButtonChange(e:KeyButtonEvent) {
        propEditor.source = e.button.key;
    }

    public function addNewButton(_):KeyButton {
        var id = keyboard.getNextId();
        var key = new Key(id);
        keyboard.addKey(key);
        var button = cMechanical.addKey(key);
        cMechanical.activeButton = button;
        return button;
    }
}
