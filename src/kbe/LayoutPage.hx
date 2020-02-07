package kbe;

import haxe.ui.data.ListDataSource;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Button;
import kbe.components.KeyboardContainer;
import kbe.components.KeyboardContainer.KeyButtonEvent;
import kbe.KeyBoard.KeyboardLayout;
import kbe.KeyBoard.KeyboarLayoutAutoConnectMode;
import kbe.components.OneWayButton;
import kbe.KeyVisualizer;

private enum ColorMode {
	Unassigned;
	MappingPairs;
}

private enum LabelMode {
	Common(v:KeyLabelMode);
	SameAsTop;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/layout_page.xml"))
class LayoutPage extends HBox implements EditorPage {
	var editor:Editor;
	var directionDown = true;
	// flag to prevent infinite recursion when changing selection from code
	var disableRecursion:Bool = false;

	var layoutLabelMode = Common(Name);
	var keyboardLabelMode = SameAsTop;
	var colorMode = ColorMode.Unassigned;

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

		layoutView.formatButton = formatLayoutButton;
		keyboardView.formatButton = formatKeyboardButton;
		layoutView.selectionMode = SingleToggle;
		keyboardView.selectionMode = SingleToggle;

		var labelModes = KeyVisualizer.COMMON_LABEL_MODES.map(data -> {
			value: data.value,
			mode: Common(data.mode)
		});
		keyboardLabelSelection.dataSource = new ListDataSource<Dynamic>();
		layoutLabelSelection.dataSource = new ListDataSource<Dynamic>();
		colorSelection.dataSource = new ListDataSource<Dynamic>();
		keyboardLabelSelection.dataSource.add({value: "Same as layout", mode: SameAsTop});
		for (mode in labelModes) {
			layoutLabelSelection.dataSource.add(mode);
			keyboardLabelSelection.dataSource.add(mode);
		}
		for (mode in [
			{value: "Unassigned", mode: ColorMode.Unassigned},
			{value: "Mapping", mode: ColorMode.MappingPairs}
		]) {
			colorSelection.dataSource.add(mode);
		}

		autoConnectMode.dataSource = new ListDataSource<Dynamic>();
		for (mode in [
			{value: "Name and position", mode: KeyboarLayoutAutoConnectMode.NamePos},
			{value: "Name", mode: KeyboarLayoutAutoConnectMode.NameOnly},
			{value: "Position", mode: KeyboarLayoutAutoConnectMode.Position}
		]) {
			autoConnectMode.dataSource.add(mode);
		}
	}

	public function init(editor:Editor) {
		this.editor = editor;
		reload();
	}

	function formatLayoutButton(button:KeyButton) {
		formatLabel(button, layoutLabelMode);
		button.backgroundColor = null;
		var layout = selectedLayout();
		if (layout != null) {
			switch (colorMode) {
				case Unassigned:
					if (layout.mappingToGrid(button.key.id).length == 0) {
						var color:thx.color.Rgb = 0xffffff;
						if (button.selected) {
							color = color.darker(0.20);
						}
						button.backgroundColor = color.toInt();
					}
				case MappingPairs:
					if (layout.mappingToGrid(button.key.id).length != 0) {
						button.backgroundColor = KeyVisualizer.getIndexedColor(button.key.id, button.selected);
					}
			}
		}
	}

	function formatKeyboardButton(button:KeyButton) {
		formatLabel(button, keyboardLabelMode);
		button.backgroundColor = null;
		var layout = selectedLayout();
		if (layout == null) {
			return;
		}
		switch (colorMode) {
			case Unassigned:
				if (layout.mappingFromGrid(button.key.id) == null) {
					var color:thx.color.Rgb = 0xffffff;
					if (button.selected) {
						color = color.darker(0.20);
					}
					button.backgroundColor = color.toInt();
				}
			case MappingPairs:
				var mapping = layout.mappingFromGrid(button.key.id);
				if (mapping != null) {
					button.backgroundColor = KeyVisualizer.getIndexedColor(mapping, button.selected);
				}
		}
	}

	function refreshFormat() {
		layoutView.refreshFormatting();
		keyboardView.refreshFormatting();
	}

	function formatLabel(button:KeyButton, mode:LabelMode) {
		switch mode {
			case Common(v):
				KeyVisualizer.updateButtonLabel(button, v);
			case SameAsTop:
				{
					var mode = layoutLabelMode;
					if (mode == SameAsTop) {
						KeyVisualizer.updateButtonLabel(button, Name);
					} else {
						formatLabel(button, mode);
					}
				}
		}
	}

	function selectedLayout():Null<KeyboardLayout> {
		var item:Dynamic = layoutSelect.selectedItem;
		if (item != null) {
			return item.layout;
		}
		return null;
	}

	function selectLayoutByName(layout:String) {
		var ds = layoutSelect.dataSource;
		if (layoutSelect.dataSource.size == 0) {
			return;
		}
		for (i in 0...ds.size) {
			var item = ds.get(i);
			if (item.layout.name == layout) {
				layoutSelect.selectedIndex = i;
				onLayoutChanged(null);
				return;
			}
		}
		layoutSelect.selectedIndex = 0;
		onLayoutChanged(null);
	}

	function reloadLayouts() {
		var previousIndex = layoutSelect.selectedIndex;
		var ds = layoutSelect.dataSource;
		// ds.allowCallbacks = false;
		ds.clear();
		for (layout in editor.getKeyboard().layouts) {
			ds.add({value: layout.name, layout: layout});
		}
		// ds.allowCallbacks = true;
		layoutSelect.selectedIndex = -1;
		layoutSelect.selectedIndex = previousIndex < 0 ? 0 : previousIndex;
		onLayoutChanged(null);
	}

	public function reload() {
		reloadLayouts();
		keyboardView.loadFromList(editor.getKeyboard().keys);
		refreshFormat();
	}

	function updateStatistics() {
		var keyboard = editor.getKeyboard();
		var currentLayout = selectedLayout();
		if (currentLayout == null) {
			return;
		}
		var unassignedKeyboard = 0;
		for (key in keyboard.keys) {
			if (currentLayout.mappingFromGrid(key.id) == null) {
				unassignedKeyboard++;
			}
		}
		var unassignedLayout = 0;
		for (key in currentLayout.keys) {
			if (currentLayout.mappingToGrid(key.id).length == 0) {
				unassignedLayout++;
			}
		}
		unsassignedKeyboardKeysLabel.text = '${unassignedKeyboard}';
		unsassignedLayoutKeysLabel.text = '${unassignedLayout}';
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
		refreshFormat();
		updateStatistics();
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
			editor.removeLayout(editor.getKeyboard().getLayoutByName(layout.name));
			reloadLayouts();
		}
	}

	function selectLastLayout() {
		layoutSelect.selectedIndex = layoutSelect.dataSource.size;
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
		} else if (!e.software && !layout.synchronised) {
			var keyboardButton = keyboardView.activeButton;
			var layoutButton = layoutView.activeButton;
			var keyboardId = -1;
			if (keyboardButton != null) {
				keyboardId = keyboardButton.key.id;
			}
			var layoutId = -1;
			if (layoutButton != null) {
				layoutId = layoutButton.key.id;
			}
			if (btnExclusive.selected) {
				editor.addLayoutMappingFromLayoutExclusive(layout, keyboardId, layoutId);
			} else {
				editor.addLayoutMapping(layout, keyboardId, layoutId);
			}
			updateStatistics();
		}
		refreshFormat();
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
		} else if (!e.software && !layout.synchronised) {
			var keyboardButton = keyboardView.activeButton;
			var layoutButton = layoutView.activeButton;
			var keyboardId = -1;
			if (keyboardButton != null) {
				keyboardId = keyboardButton.key.id;
			}
			var layoutId = -1;
			if (layoutButton != null) {
				layoutId = layoutButton.key.id;
			}
			if (btnExclusive.selected) {
				editor.addLayoutMappingFromLayoutExclusive(layout, keyboardId, layoutId);
			} else {
				editor.addLayoutMapping(layout, keyboardId, layoutId);
			}
			updateStatistics();
		}
		refreshFormat();
	}

	@:bind(layoutLabelSelection, UIEvent.CHANGE)
	function layoutLabelSelectionChanged(_) {
		var modeData = layoutLabelSelection.selectedItem;
		if (modeData != null) {
			layoutLabelMode = modeData.mode;
		}
		layoutView.refreshFormatting();
		if (keyboardLabelMode == SameAsTop) {
			keyboardView.refreshFormatting();
		}
	}

	@:bind(keyboardLabelSelection, UIEvent.CHANGE)
	function keyboardLabelSelectionChanged(_) {
		var modeData = keyboardLabelSelection.selectedItem;
		if (modeData != null) {
			keyboardLabelMode = modeData.mode;
		}
		keyboardView.refreshFormatting();
	}

	@:bind(colorSelection, UIEvent.CHANGE)
	function colorModeChanged(_) {
		var modeData = colorSelection.selectedItem;
		if (modeData != null) {
			colorMode = modeData.mode;
		}
		keyboardView.refreshFormatting();
		layoutView.refreshFormatting();
	}

	@:bind(btnAuto, MouseEvent.CLICK)
	function onAutoConnectClicked(_) {
		var layout = {
			var currentLayout = selectedLayout();
			if (currentLayout == null) {
				return;
			}
			currentLayout.clone();
		};
		if (layout.synchronised) {
			return;
		}
		var keyboard = editor.getKeyboard();
		var mode = autoConnectMode.selectedItem.mode;
		layout.autoConnectInMode(keyboard, mode, autoConnectUnassigned.selected, autoConnectLimitStepper.pos);
		editor.updateLayout(layout.name, layout);
		reload();
	}
}
