package;

import components.properties.PropertyEditor;
import haxe.ui.containers.HBox;
import components.OneWayButton;
import haxe.ui.core.MouseEvent;
import components.KeyboardContainer;
import components.KeyboardContainer.KeyButtonEvent;

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

	public function activate() {}

	public function deactivate() {}
}

class AddTool extends MoveTool {
	function doAdd(e:MouseEvent) {
		var btn = page.addNewButton(true);
		var key = btn.key;
		var field = page.cMechanical;
		var p = field.screenToField(e.screenX, e.screenY);
		key.x = p.x;
		key.y = p.y;
		btn.refresh();
		page.onKeyMove(btn);
		page.propEditor.source = key;
		return btn;
	}

	function onAdd(e:MouseEvent) {
		var button = doAdd(e);
		this.movableButton = button;
	}

	override function activate() {
		page.cMechanical.registerEvent(MouseEvent.MOUSE_DOWN, onAdd);
		page.cMechanical.registerEvent(MouseEvent.MOUSE_UP, onMouseUp);
		page.cMechanical.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

	override function deactivate() {
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_DOWN, onAdd);
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_UP, onMouseUp);
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_UP, onMouseMove);
	}
}

class RemoveTool extends Tool {
	function buttonClicked(e:KeyButtonEvent) {
		page.eraseButton(e.button);
	}

	override function activate() {
		page.cMechanical.registerEvent(KeyboardContainer.BUTTON_CHANGED, buttonClicked);
	}

	override function deactivate() {
		page.cMechanical.unregisterEvent(KeyboardContainer.BUTTON_CHANGED, buttonClicked);
	}
}

class SelectTool extends Tool {
	// TODO:implement
}

class MoveTool extends Tool {
	var movableButton:KeyButton;

	function onMouseDown(e:KeyButtonEvent) {
		page.cMechanical.activeButton = e.button;
		movableButton = e.button;
	}

	function onMouseUp(e:MouseEvent) {
		movableButton = null;
	}

	function onMouseMove(e:MouseEvent) {
		if (movableButton == null || !e.buttonDown) {
			return;
		}
		var p = page.cMechanical.screenToField(e.screenX, e.screenY);
		movableButton.key.x = p.x;
		movableButton.key.y = p.y;

		page.onKeyMove(movableButton);
		movableButton.refresh();
		page.cMechanical.updateLayout();
	}

	override function activate() {
		page.cMechanical.registerEvent(KeyboardContainer.BUTTON_DOWN, onMouseDown);
		page.cMechanical.registerEvent(MouseEvent.MOUSE_UP, onMouseUp);
		// page.cMechanical.registerEvent(MouseEvent.MOUSE_OUT, onMouseUp);
		page.cMechanical.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

	override function deactivate() {
		page.cMechanical.unregisterEvent(KeyboardContainer.BUTTON_DOWN, onMouseDown);
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_UP, onMouseUp);
		//  page.cMechanical.unregisterEvent(MouseEvent.MOUSE_OUT, onMouseUp);
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_UP, onMouseMove);
	}
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

		tools = createTools();
		bindToolButtons();

		bAddRight.onClick = addRight;
		bAddDown.onClick = addDown;
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
		toolButtons = [Add => bAdd, Remove => bRemove, Move => bMove, Select => bSelect];
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

	function refreshProperties() {
		propEditor.source = cMechanical.activeButton == null ? null : cMechanical.activeButton.key;
	}

	public function addNewButton(activate:Bool = true):KeyButton {
		var id = keyboard.getNextId();
		var key = new Key(id);
		keyboard.addKey(key);
		var button = cMechanical.addKey(key);
		if (activate) {
			cMechanical.activeButton = button;
		}
		onKeyMove(button);
		return button;
	}

	public function eraseButton(btn:KeyButton) {
		if (btn == null) {
			return;
		}
		keyboard.removeKey(btn.key);
		cMechanical.removeKey(btn);
	}

	function addRight(_) {
		if (cMechanical.activeButton == null) {
			return;
		}
		var prevKey = cMechanical.activeButton.key;
		var button = addNewButton();
		var key = button.key;
		key.y = prevKey.y;
		key.x = prevKey.x + prevKey.width;
		key.height = prevKey.height;
		button.refresh();
		refreshProperties();
	}

	function addDown(_) {
		if (cMechanical.activeButton == null) {
			return;
		}
		var prevKey = cMechanical.activeButton.key;
		var button = addNewButton();
		var key = button.key;
		key.y = prevKey.y + prevKey.height;
		key.x = prevKey.x;
		key.width = prevKey.width;
		button.refresh();
		refreshProperties();
	}

	public function onKeyMove(key:KeyButton) {
		var rnd = function(val:Float, step:Float):Float {
			return Math.fround(val / step) * step;
		};
		if (bAlign.selected) {
			var st:Float = alignStep.number;
			key.key.x = rnd(key.key.x, st);
			key.key.y = rnd(key.key.y, st);
			key.refresh();
			refreshProperties();
		}
	}
}
