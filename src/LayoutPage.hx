package;

import haxe.ui.data.ListDataSource;
import haxe.ui.data.DataSource;
import haxe.ui.events.UIEvent;
import KeyBoard.KeyboardLayout;
import haxe.ui.util.StringUtil;
import haxe.ui.util.Color;
import haxe.ui.containers.HBox;
import components.OneWayButton;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Button;
import components.KeyboardContainer;
import components.KeyboardContainer.KeyButtonEvent;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layout_page.xml"))
class LayoutPage extends HBox implements EditorPage {
	var editor:Editor;

	public function new() {
		super();
		text = "Layout";
		percentWidth = 100;
		percentHeight = 100;
		layoutSelect.dataSource = new ListDataSource<Dynamic>();
		// keyView.registerEvent(KeyboardContainer.BUTTON_CHANGED, onButtonChange);
		// propEditor.onChange = onPropertyChange;
		// keyView.formatButton = formatButton;
	}

	public function init(editor:Editor) {
		this.editor = editor;
		reload();
	}

	function formatButton(button:KeyButton) {
		/*var key = button.key;
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
		}*/
	}

	function selectedLayout():KeyboardLayout {
		// var item:Dynamic = layoutSelect.selectedItem;
		var index = layoutSelect.selectedIndex;
		if (index < 0 || index >= layoutSelect.dataSource.size) {
			return null;
		}
		var item:Dynamic = layoutSelect.dataSource.get(layoutSelect.selectedIndex);
		// trace('selectedLayout ${layoutSelect.selectedIndex} ${item} ${layoutSelect.dataSource.get(layoutSelect.selectedIndex)}');
		if (item != null) {
			return item.layout;
		}
		return null;
	}

	function selectLayout(layout:KeyboardLayout) {
		var ds = layoutSelect.dataSource;
		if (layoutSelect.dataSource.size == 0) {
			return;
		}
		for (i in 0...ds.size) {
			var item = ds.get(i);
			if (item.layout == layout) {
				layoutSelect.selectedIndex = i;
				onLayoutChanged(null);
				return;
			}
		}
		layoutSelect.selectedIndex = 0;
		onLayoutChanged(null);
	}

	function reloadLayouts() {
		var previousLayout = selectedLayout();
		var ds = layoutSelect.dataSource;
		// ds.allowCallbacks = false;
		ds.clear();
		for (layout in editor.getKeyboard().layouts) {
			ds.add({value: layout.name, layout: layout});
		}
		// ds.allowCallbacks = true;
		layoutSelect.selectedIndex = -1;
		selectLayout(previousLayout);
	}

	public function reload() {
		reloadLayouts();
		keyboardView.loadFromList(editor.getKeyboard().keys);
	}

	@:bind(layoutSelect, UIEvent.CHANGE)
	function onLayoutChanged(_) {
		var layout = selectedLayout();

		if (layout == null) {
			nameField.text = "";
		} else {
			nameField.text = layout.name;
			layoutView.loadFromList(layout.keys);
		}
	}

	@:bind(nameField, UIEvent.CHANGE)
	function onNameChanged(_) {
		var layout = selectedLayout();

		if (layout != null) {
			editor.renameLayout(layout, nameField.text);
		}
		reloadLayouts();
	}

	@:bind(layoutAdd, MouseEvent.CLICK)
	function newLayout(_) {
		var layout = editor.newLayout();
		reloadLayouts();
		selectLastLayout();
	}

	@:bind(layoutRemove, MouseEvent.CLICK)
	function removeLayout(_) {
		editor.removeLayout(selectedLayout());
		reloadLayouts();
	}

	function selectLastLayout() {
		var keyboard = editor.getKeyboard();
		var lastLay = keyboard.layouts[keyboard.layouts.length - 1];
		selectLayout(lastLay);
	}

	@:bind(layoutFromThis, MouseEvent.CLICK)
	function creatLayoutFromThis(_) {
		editor.newLayoutFromKeys(editor.getKeyboard().keys);
		reloadLayouts();
		selectLastLayout();
	}

	@:bind(layoutImport, MouseEvent.CLICK)
	function layoutFromImported(_) {}
}
