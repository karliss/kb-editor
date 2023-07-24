package kbe;

import haxe.ui.util.ColorUtil;
import haxe.ui.util.Color;
import haxe.io.Bytes;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.Toolkit;
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
			text: data.text,
			mode: Common(data.mode)
		});
		keyboardLabelSelection.dataSource = new ListDataSource<Dynamic>();
		layoutLabelSelection.dataSource = new ListDataSource<Dynamic>();
		colorSelection.dataSource = new ListDataSource<Dynamic>();
		keyboardLabelSelection.dataSource.add({text: "Same as layout", mode: SameAsTop});
		for (mode in labelModes) {
			layoutLabelSelection.dataSource.add(mode);
			keyboardLabelSelection.dataSource.add(mode);
		}
		for (mode in [
			{text: "Unassigned", mode: ColorMode.Unassigned},
			{text: "Mapping", mode: ColorMode.MappingPairs}
		]) {
			colorSelection.dataSource.add(mode);
		}

		autoConnectMode.dataSource = new ListDataSource<Dynamic>();
		for (mode in [
			{text: "Name and position", mode: KeyboarLayoutAutoConnectMode.NamePos},
			{text: "Name", mode: KeyboarLayoutAutoConnectMode.NameOnly},
			{text: "Position", mode: KeyboarLayoutAutoConnectMode.Position}
		]) {
			autoConnectMode.dataSource.add(mode);
		}

		importFormat.dataSource = new ListDataSource<Exporter.Importer>();
		for (importer in FormatManager.getImporters()) {
			importFormat.dataSource.add(importer);
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
						var color:Color = 0xffffff;
						if (button.selected) {
							var hsl = ColorUtil.toHSL(color);
							hsl.l -= 0.2;
							color = ColorUtil.fromHSL(hsl.h, hsl.s, hsl.l);
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
					var color = button.selected ? ColorUtil.fromHSL(0, 0, 1) : ColorUtil.fromHSL(0, 0, 0.8);
					button.backgroundColor = color;
				}
			case MappingPairs:
				var mapping = layout.mappingFromGrid(button.key.id);
				if (mapping != null) {
					button.backgroundColor = KeyVisualizer.getIndexedColor(mapping, button.selected);
				}
		}
	}

	@:bind(keyViewScale, UIEvent.CHANGE)
	function keyViewScaleChange(e:UIEvent) {
		layoutView.scale = keyViewScale.value;
		keyboardView.scale = keyViewScale.value;
	}

	function refreshFormat() {
		layoutView.refreshFormatting();
		keyboardView.refreshFormatting();
	}

	function formatLabel(button:KeyButton, mode:LabelMode) {
		switch mode {
			case Common(v):
				KeyVisualizer.updateButtonLabel(editor.getKeyboard(), button, v);
			case SameAsTop:
				{
					var mode = layoutLabelMode;
					if (mode == SameAsTop) {
						KeyVisualizer.updateButtonLabel(editor.getKeyboard(), button, Name);
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
			ds.add({text: layout.name, layout: layout});
		}
		// ds.allowCallbacks = true;
		layoutSelect.selectedIndex = -1;
		layoutSelect.selectedIndex = previousIndex < 0 || previousIndex >= layoutSelect.dataSource.size ? 0 : previousIndex;
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
			synchronizeLayout.selected = layout.synchronised;

			btnAuto.disabled = layout.synchronised;
			if (layout.synchronised) {
				btnViewOnly.selected = true;
				btnDown.selected = false;
				btnUp.selected = false;
			}
			btnUp.disabled = layout.synchronised;
			btnDown.disabled = layout.synchronised;
		}
		refreshFormat();
		updateStatistics();
	}

	@:bind(nameField, UIEvent.CHANGE)
	function onNameChanged(_) {
		var layout = selectedLayout();

		if (layout != null) {
			if (layout.name == nameField.text) {
				return;
			}
			trace('renaming layout'); // TODO: test
			editor.renameLayout(layout, nameField.text);
			reloadLayouts();
		}
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
		var i = layoutSelect.dataSource.size - 1;
		layoutSelect.selectedIndex = layoutSelect.dataSource.size - 1;
		onLayoutChanged(null);
	}

	@:bind(layoutFromThis, MouseEvent.CLICK)
	function creatLayoutFromThis(_) {
		var layout = new KeyboardLayout();
		layout.synchronised = true;
		editor.addLayout(layout);
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

	@:bind(synchronizeLayout, MouseEvent.CLICK)
	function onSynchronizeClicked(_) {
		var layout = {
			var currentLayout = selectedLayout();
			if (currentLayout == null) {
				return;
			}
			currentLayout.clone();
		};
		layout.synchronised = !layout.synchronised;
		editor.updateLayout(layout.name, layout);
		reload();
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

	function handleImportLayoutFile(bytes:Array<Bytes>, names:Array<String>) {
		var importer = importFormat.selectedItem;
		if (importer == null) {
			haxe.ui.containers.dialogs.Dialogs.messageBox("Format not selected", null, MessageBoxType.TYPE_WARNING);
			return;
		}
		try {
			var result:KeyBoard = importer.convert(bytes[0], names[0]);
			var layouts = result.layouts;

			var hasSynchronised = false;
			var count = 0;
			for (layout in layouts) {
				if (layout.synchronised) {
					hasSynchronised = true;
				}
				layout.synchronised = false;
				layout.clearMapping();
				editor.addLayout(layout);
				count += 1;
			}
			if (!hasSynchronised) {
				var layout = new KeyboardLayout();
				layout.setKeys(result.keys, false);
				editor.addLayout(layout);
				count += 1;
			}
			if (count > 0) {
				reloadLayouts();
				selectLastLayout();
			}
			Dialogs.messageBox('Imported $count layouts', null, MessageBoxType.TYPE_INFO);
		} catch (e:Dynamic) {
			Dialogs.messageBox('Import error "$e"', null, MessageBoxType.TYPE_ERROR);
		}
	}

	@:bind(layoutImport, MouseEvent.CLICK)
	function onClickImport(_):Void {
		// TODO: remove if js
		#if js
		FileOpener.tryToOpenFile(function(bytes, names) {
			handleImportLayoutFile(bytes, names);
		});
		#end
	}
}
