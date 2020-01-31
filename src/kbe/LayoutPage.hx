package kbe;

import haxe.ui.data.ListDataSource;
import haxe.ui.data.DataSource;
import haxe.ui.events.UIEvent;
import haxe.ui.util.StringUtil;
import haxe.ui.util.Color;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Button;
import kbe.components.KeyboardContainer;
import kbe.components.KeyboardContainer.KeyButtonEvent;
import kbe.KeyBoard.KeyboardLayout;
import kbe.components.OneWayButton;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layout_page.xml"))
class LayoutPage extends HBox implements EditorPage {
	var editor:Editor;
	var directionDown = true;
	// flag to prevent infinite recursion when changing selection from code
	var disableRecursion:Bool = false;

	public function new(?editor:Editor) {
		super();
		if (editor == null) {
			throw "bad call";
		}

		this.editor = editor;
		text = "Layout";
		percentWidth = 100;
		percentHeight = 100;
		layoutSelect.dataSource = new ListDataSource<Dynamic>();
		btnDown.selected = true;
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

	function selectedLayout():Null<KeyboardLayout> {
		var item:Dynamic = layoutSelect.selectedItem;
		if (item != null) {
			return item.layout;
		}
		return null;
	}

	function selectLayout(layout:Null<KeyboardLayout>) {
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
	function onLayoutChanged(_:Null<Dynamic>) {
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
		var layout = selectedLayout();
		if (layout != null) {
			editor.removeLayout(layout);
			reloadLayouts();
		}
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

	@:bind(btnDown, MouseEvent.CLICK)
	function switchDown(_) {
		directionDown = true;
		btnUp.selected = false;
		btnViewOnly.selected = false;
	}

	@:bind(btnUp, MouseEvent.CLICK)
	function switchUp(_) {
		directionDown = false;
		btnDown.selected = false;
		btnViewOnly.selected = false;
	}

	@:bind(btnViewOnly, MouseEvent.CLICK)
	function switchViewMode(_) {
		btnDown.selected = false;
		btnUp.selected = false;
	}

	@:bind(layoutView, KeyboardContainer.BUTTON_CHANGED)
	function clickUp(e:KeyButtonEvent) {
		if (disableRecursion) {
			return;
		}
		var layout = selectedLayout();
		if (layout == null) {
			return;
		}
		if (btnViewOnly.selected || directionDown) {
			disableRecursion = true;
			var topButton = layoutView.activeButton;

			keyboardView.activeButton = null;
			if (topButton != null) {
				var keyboardIds = layout.mappingToGrid(topButton.key.id);
				for (key in keyboardView.buttons) {
					if (keyboardIds.indexOf(key.key.id) > -1) {
						keyboardView.selectButton(key, Add);
					}
				}
			}
			disableRecursion = false;
		} else {
			var layoutButton = layoutView.activeButton;
			if (layoutButton == null) {
				return;
			}
			if (btnExclusive.selected) {
				var keyboardButton = keyboardView.activeButton;
				if (keyboardButton != null) {
					editor.addLayoutMappingFromLayoutExclusive(layout, keyboardButton.key.id, layoutButton.key.id);
				} else {
					editor.addLayoutMappingFromLayoutExclusive(layout, -1, layoutButton.key.id);
				}
			} else {
				var keyboardButton = keyboardView.activeButton;
				if (keyboardButton != null) {
					editor.addLayoutMapping(layout, keyboardButton.key.id, layoutButton.key.id);
				}
			}
		}
	}

	@:bind(keyboardView, KeyboardContainer.BUTTON_CHANGED)
	function clickDown(e:KeyButtonEvent) {
		if (disableRecursion) {
			return;
		}
		var layout = selectedLayout();
		if (layout == null) {
			return;
		}
		if (btnViewOnly.selected || !directionDown) {
			disableRecursion = true;
			var keyboardKey = keyboardView.activeButton;
			layoutView.activeButton = null;
			if (keyboardKey != null) {
				var id = layout.mappingFromGrid(keyboardKey.key.id);
				if (id != null) {
					for (button in layoutView.buttons) {
						if (button.key.id == id) {
							layoutView.activeButton = button;
						}
					}
				}
			}
			disableRecursion = false;
		} else {
			var keyboardButton = keyboardView.activeButton;
			var layoutButton = layoutView.activeButton;
			if (keyboardButton == null) {
				return;
			}
			if (layoutButton != null) {
				editor.addLayoutMapping(layout, keyboardButton.key.id, layoutButton.key.id);
			} else {
				editor.addLayoutMapping(layout, keyboardButton.key.id, -1);
			}
		}
	}
}
