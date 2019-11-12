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
class WiringPage extends HBox {
	var keyboard:KeyBoard;

	public function new() {
		super();
		percentWidth = 100;
		percentHeight = 100;
		text = "Wiring";

		keyView.registerEvent(KeyboardContainer.BUTTON_CHANGED, onButtonChange);
		propEditor.onChange = onPropertyChange;
		keyView.formatButton = formatButton;
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
		}
	}

	public function setKeyboard(keyboard:KeyBoard) {
		this.keyboard = keyboard;
		reload();
	}

	function refreshFormatting() {
		keyView.refreshFormatting();
	}

	function onPropertyChange(_) {
		refreshFormatting();
	}

	function onButtonChange(e:KeyButtonEvent) {
		propEditor.source = e.button != null ? e.button.key : null;
		refreshFormatting();
	}

	function refreshProperties() {
		propEditor.source = keyView.activeButton == null ? null : keyView.activeButton.key;
	}

	public function reload() {
		keyView.loadFromList(keyboard.keys);
	}
}
