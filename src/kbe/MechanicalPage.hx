package kbe;

import haxe.ui.events.UIEvent;
import haxe.ui.data.ListDataSource;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.components.Button;
import kbe.components.properties.PropertyEditor;
import kbe.components.OneWayButton;
import kbe.components.KeyboardContainer;
import kbe.components.KeyboardContainer.KeyButtonEvent;

enum ToolType {
	Add;
	Remove;
	Move;
	Select;
}

class Tool {
	public var page:MechanicalPage;

	var editor:Editor;

	public function new(p:MechanicalPage, editor:Editor) {
		page = p;
		this.editor = editor;
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
		editor.moveKey(key, p.x, p.y, true);
		page.onKeyMove(btn);
		return btn;
	}

	function onAdd(e:MouseEvent) {
		var button = doAdd(e);
		this.movableButtons = [button];
		this.offsets = [{x: 0, y: 0}];
		firstMove = false;
	}

	override function activate() {
		page.cMechanical.selectionMode = SingleSet;
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
		var button = e.button;
		if (button != null) {
			page.eraseButton(button);
		}
	}

	override function activate() {
		page.cMechanical.selectionMode = SingleSet;
		page.cMechanical.registerEvent(KeyboardContainer.BUTTON_CLICKED, buttonClicked);
	}

	override function deactivate() {
		page.cMechanical.unregisterEvent(KeyboardContainer.BUTTON_CLICKED, buttonClicked);
	}
}

class SelectTool extends Tool {
	override function activate() {
		page.cMechanical.selectionMode = MultiSelect;
		page.cMechanical.rectangleSelection = true;
	}

	override function deactivate() {
		page.cMechanical.rectangleSelection = false;
	}
}

class MoveTool extends Tool {
	var movableButtons:Null<Array<KeyButton>> = null;
	var offsets:Array<Point> = [];
	var firstMove = true;
	var buttonToToggle:Null<KeyButton> = null;

	function onMouseDown(e:KeyButtonEvent) {
		buttonToToggle = null;
		var button = e.button;
		if (e.mouseEvent == null || button == null) {
			return;
		}
		var container = page.cMechanical;
		buttonToToggle = button;
		if (e.mouseEvent.shiftKey) {
			container.selectButton(button, Toggle);
		} else if (container.activeButtons().indexOf(button) >= 0) {
			container.selectButton(button, Add);
		} else {
			container.selectButton(button, Set);
		}
		movableButtons = page.cMechanical.activeButtons().copy();

		var p = page.cMechanical.screenToField(e.mouseEvent.screenX, e.mouseEvent.screenY);
		offsets = movableButtons.map(movableButton -> {
			var p2 = new haxe.ui.geom.Point(movableButton.key.x, movableButton.key.y);
			return {x: movableButton.key.x - p.x, y: movableButton.key.y - p.y};
		});
		firstMove = true;
	}

	function onMouseUp(e:MouseEvent) {
		movableButtons = null;
	}

	function onButtonClicked(e:MouseEvent) {
		if (buttonToToggle != null && page.cMechanical.activeButtons().indexOf(buttonToToggle) < 0) {
			// Deselect button when shift clicking
			buttonToToggle.selected = false;
			buttonToToggle = null;
		}
	}

	function onMouseMove(e:MouseEvent) {
		if (movableButtons == null || !e.buttonDown || movableButtons.length == 0) {
			return;
		}
		var p = page.cMechanical.screenToField(e.screenX, e.screenY);
		var index = 0;
		var ids = new Array<Int>();
		var positions = new Array<Key.Point>();
		var minOffset:Point = {x: offsets[0].x, y: offsets[0].y};
		for (offset in offsets) {
			minOffset.x = Math.min(minOffset.x, offset.x);
			minOffset.y = Math.min(minOffset.y, offset.y);
		}
		p.x = Math.max(p.x, -minOffset.x);
		p.y = Math.max(p.y, -minOffset.y);
		for (movableButton in movableButtons) {
			ids.push(movableButton.key.id);
			positions.push({x: p.x + offsets[index].x, y: p.y + offsets[index].y});
			index++;
		}
		editor.moveKeys(ids, positions, !firstMove);
		firstMove = false;
		for (button in movableButtons) {
			page.onKeyMove(button);
		}
		page.cMechanical.updateLayout();
	}

	override function activate() {
		page.cMechanical.selectionMode = None;
		page.cMechanical.registerEvent(KeyboardContainer.BUTTON_DOWN, onMouseDown);
		page.cMechanical.registerEvent(KeyboardContainer.BUTTON_CLICKED, onButtonClicked);
		page.cMechanical.registerEvent(MouseEvent.MOUSE_UP, onMouseUp);
		// page.cMechanical.registerEvent(MouseEvent.MOUSE_OUT, onMouseUp);
		page.cMechanical.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMove);
		page.cMechanical.rectangleSelection = true;
	}

	override function deactivate() {
		page.cMechanical.unregisterEvent(KeyboardContainer.BUTTON_DOWN, onMouseDown);
		page.cMechanical.unregisterEvent(KeyboardContainer.BUTTON_CLICKED, onButtonClicked);
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_UP, onMouseUp);
		//  page.cMechanical.unregisterEvent(MouseEvent.MOUSE_OUT, onMouseUp);
		page.cMechanical.unregisterEvent(MouseEvent.MOUSE_MOVE, onMouseMove);
		page.cMechanical.rectangleSelection = false;
	}
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/mechanical_page.xml"))
class MechanicalPage extends HBox implements EditorPage {
	var editor:Editor;
	var tool:ToolType = Select;
	var tools:Map<ToolType, Tool> = [];
	var toolButtons:Map<ToolType, Button> = [];
	var currentTool:Null<Tool> = null;

	public function new(?editor:Editor) {
		if (editor == null) {
			throw "Bad call";
		}
		this.editor = editor;
		super();

		cMechanical.registerEvent(KeyboardContainer.BUTTON_CHANGED, onButtonChange);
		cMechanical.formatButton = formatButton;
		propEditor.onChange = onPropertyChange;

		bAddRight.onClick = addRight;
		bAddDown.onClick = addDown;

		bAlign.onClick = function(_) {
			editor.alignButtons = bAlign.selected;
		};
		alignStep.onChange = function(_) {
			editor.alignment = alignStep.value;
		};

		percentWidth = 100;
		percentHeight = 100;
		text = "Mechanical";

		keyLabelSelection.dataSource = new ListDataSource<Dynamic>();
		for (mode in KeyVisualizer.COMMON_LABEL_MODES) {
			keyLabelSelection.dataSource.add(mode);
		}
		keyLabelSelection.selectedIndex = 0;
	}

	public function init(editor:Editor) {
		this.editor = editor;
		tools = createTools();
		bindToolButtons();
		reload();
	}

	@:bind(cMechanical, KeyboardEvent.KEY_UP)
	function onTopKeyDown(e:KeyboardEvent) {
		switch (e.keyCode) {
			case KC.R:
				selectTool(ToolType.Remove);
			case KC.A:
				selectTool(ToolType.Add);
			case KC.M:
				selectTool(ToolType.Move);
			case KC.S:
				selectTool(ToolType.Select);
		}
	}

	function createTools():Map<ToolType, Tool> {
		var result:Map<ToolType, Tool> = [
			Add => new AddTool(this, editor),
			Remove => new RemoveTool(this, editor),
			Move => new MoveTool(this, editor),
			Select => new SelectTool(this, editor),
		];

		return result;
	}

	function selectTool(type:ToolType) {
		var tool = tools.get(type);
		var btn = toolButtons.get(type);
		if (tool == null || btn == null) {
			throw "should not happen";
		}
		if (tool == currentTool) {
			return;
		}
		if (currentTool != null) {
			currentTool.deactivate();
		}
		currentTool = tool;
		currentTool.activate();
		toolButtonBar.selectedButton = btn;
	}

	function bindToolButtons() {
		toolButtons = [
			Add => cast(bAdd, Button),
			Remove => cast(bRemove, Button),
			Move => cast(bMove, Button),
			Select => bSelect
		];
		for (toolType in toolButtons.keys()) {
			var button = toolButtons.get(toolType);
			if (button == null) {
				throw "Unexpected tool, should not happen";
			}
			button.onClick = function(_) {
				selectTool(toolType);
			};
		}
	}

	function onPropertyChange(_) {
		var changedObject:Map<String, Null<Dynamic>> = propEditor.source;
		if (changedObject == null) {
			return;
		}
		var buttons = cMechanical.activeButtons();
		var ids = buttons.map(button -> button.key.id);
		var changes = new Map<String, Dynamic>();
		for (field => value in changedObject) {
			if (value != null) {
				changes.set(field, value);
			}
		}
		editor.modifyKeys(ids, [for (_ in 0...ids.length) changes]);

		cMechanical.refreshFormatting();
		cMechanical.updateLayout();
	}

	function onButtonChange(e:KeyButtonEvent) {
		refreshProperties();
	}

	function prepareSelectionPropertyDescription():Map<String, Null<Dynamic>> {
		var result:Map<String, Null<Dynamic>> = [];
		var buttons = cMechanical.activeButtons();
		if (buttons.length == 0) {
			return result;
		}
		for (field in Reflect.fields(buttons[0].key)) {
			result.set(field, Reflect.getProperty(buttons[0].key, field));
		}
		for (button in buttons) {
			var key = button.key;
			for (field in Reflect.fields(key)) {
				var value = Reflect.getProperty(key, field);
				if (value != result.get(field)) {
					result.set(field, null);
				}
			}
		}
		return result;
	}

	function refreshProperties() {
		propEditor.source = prepareSelectionPropertyDescription();
	}

	public function addNewButton(activate:Bool = true):KeyButton {
		var key = editor.addNewKey();
		var button = addKey(key, activate);
		onKeyMove(button);
		return button;
	}

	function addKey(key:Key, activate:Bool = true):KeyButton {
		var button = cMechanical.addKey(key);
		if (activate) {
			cMechanical.activeButton = button;
			refreshProperties();
		}
		return button;
	}

	public function eraseButton(btn:KeyButton) {
		if (btn == null) {
			return;
		}
		editor.removeKey(btn.key);
		cMechanical.removeKey(btn);
	}

	function addRight(_) {
		var button = cMechanical.activeButton;
		if (button == null) {
			return;
		}
		var key = editor.addRight(button.key);
		addKey(key);
	}

	function addDown(_) {
		var button = cMechanical.activeButton;
		if (button == null) {
			return;
		}
		var key = editor.addDown(button.key);
		var button = addKey(key);
	}

	public function onKeyMove(key:KeyButton) {
		cMechanical.refreshButtonFormatting(key);
		refreshProperties();
	}

	public function reload() {
		cMechanical.loadFromList(editor.getKeyboard().keys);
	}

	@:bind(bAlignX, MouseEvent.CLICK)
	function onAlignXClicked(_) {
		var selection = cMechanical.activeButtons().map(button -> button.key);
		var activeButton = cMechanical.activeButton;
		if (selection.length > 1 && activeButton != null) {
			editor.alignKeys(activeButton.key, selection, false);
			reload();
		}
	}

	@:bind(bAlignY, MouseEvent.CLICK)
	function onAlignYClicked(_) {
		var selection = cMechanical.activeButtons().map(button -> button.key);
		var button = cMechanical.activeButton;
		if (selection.length > 1 && button != null) {
			editor.alignKeys(button.key, selection, true);
			reload();
		}
	}

	@:bind(cMechanical, KeyboardEvent.KEY_DOWN)
	function onKeyDown(e:KeyboardEvent) {
		if (e.keyCode == KC.DELETE) {
			editor.removeKeys(cMechanical.activeButtons().map(button -> button.key));
			reload();
		}
	}

	@:bind(keyViewScale, UIEvent.CHANGE)
	function keyViewScaleChange(e:UIEvent) {
		cMechanical.drawScale = keyViewScale.value;
	}

	@:bind(keyLabelSelection, UIEvent.CHANGE)
	function onLayoutLabelModeChanged(e:UIEvent) {
		cMechanical.refreshFormatting();
	}

	function formatButton(button:KeyButton) {
		KeyVisualizer.updateButtonLabel(editor.getKeyboard(), button, keyLabelSelection.selectedItem.mode);
	}
}
