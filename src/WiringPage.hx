package;

import haxe.ui.util.StringUtil;
import haxe.ui.util.Color;
import components.properties.PropertyEditor;
import haxe.ui.containers.HBox;
import components.OneWayButton;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Button;
import components.KeyboardContainer;
import components.KeyboardContainer.KeyButtonEvent;

@:build(haxe.ui.macros.ComponentMacros.build("assets/wiring_page.xml"))
class WiringPage extends HBox implements EditorPage {
	var keyboard:KeyBoard;
	var editor:Editor;
	var conflictingKeys = new Map<Int, Int>();
	var bottomButton:OneWayButton = null;

	var rows = 0;
	var columns = 0;

	public function new() {
		super();
		percentWidth = 100;
		percentHeight = 100;
		text = "Wiring";

		keyView.registerEvent(KeyboardContainer.BUTTON_CHANGED, onButtonChange);
		propEditor.onChange = onPropertyChange;
		keyView.formatButton = formatButton;
	}

	public function init(editor:Editor) {
		this.editor = editor;
		reload();
	}

	function formatButton(button:KeyButton) {
		var key = button.key;
		button.text = '${StringTools.hex(key.row)} ${StringTools.hex(key.column)}';
		button.backgroundColor = null;
		var currentButton = keyView.activeButton;
		if (currentButton != null && currentButton != button) {
			var row = currentButton.key.row;
			var column = currentButton.key.column;
			if (key.row == row) {
				button.backgroundColor = 0xe0fde0;
			} else if (column == key.column) {
				button.backgroundColor = 0xe0e0fd;
			}
			if (conflictingKeys.exists(key.id)) {
				button.backgroundColor = 0xffcc00;
			}
			if (key.row == row && column == key.column && button != keyView.activeButton) {
				button.backgroundColor = 0xff6666;
			}
		}
	}

	function refreshFormatting() {
		conflictingKeys.clear();
		var badKeys = editor.getConflictingWiring();
		for (key in badKeys) {
			conflictingKeys.set(key.id, 0);
		}
		keyView.refreshFormatting();
	}

	function onPropertyChange(_) {
		refreshFormatting();
		resizeMatrix();
		syncBottomSelection();
	}

	function syncBottomSelection() {
		if (keyView.activeButton != null) {
			var key = keyView.activeButton.key;
			selectBottomButton(key.column, key.row);
		}
	}

	function onButtonChange(e:KeyButtonEvent) {
		propEditor.source = e.button != null ? e.button.key : null;
		syncBottomSelection();
		refreshFormatting();
	}

	function refreshProperties() {
		propEditor.source = keyView.activeButton == null ? null : keyView.activeButton.key;
	}

	function selectTopButton(x:Int, y:Int) {
		for (key in keyboard.keys) {
			if (key.row == y && key.column == x) {
				keyView.activeButton = keyView.getButton(key);
				return;
			}
		}
		keyView.activeButton = null;
	}

	function selectBottomButton(x:Int, y:Int) {
		if (bottomButton != null) {
			bottomButton.selected = false;
			bottomButton = null;
		}
		var button:OneWayButton = Std.downcast(matrixGrid.getComponentAt(x + y * columns), OneWayButton);
		bottomButton = button;
		button.selected = true;
	}

	function resizeMatrix() {
		var columnsNeed = 1;
		var rowsNeed = 0;
		for (key in keyboard.keys) {
			if (key.column + 1 > columnsNeed) {
				columnsNeed = key.column + 1;
			}
			if (key.row + 1 > rowsNeed) {
				rowsNeed = key.row + 1;
			}
		}
		if (columnsNeed == columns && rowsNeed == rows) {
			return;
		}
		rows = rowsNeed;
		columns = columnsNeed;
		labelRows.text = '$rows';
		labelColumns.text = '$columns';
		matrixGrid.columns = columnsNeed;
		matrixGrid.removeAllComponents();
		for (y in 0...rowsNeed) {
			for (x in 0...columnsNeed) {
				var button = new OneWayButton();
				button.width = 32;
				button.height = 32;
				button.onClick = function(_) {
					if (bottomButton != null) {
						bottomButton.selected = false;
					}
					selectTopButton(x, y);
					bottomButton = button;
				};
				matrixGrid.addComponent(button);
			}
		}
	}

	public function reload() {
		keyboard = editor.getKeyboard();
		keyView.loadFromList(keyboard.keys);
		resizeMatrix();
		refreshFormatting();
	}
}
