package kbe;

import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.ItemEvent;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.data.ListDataSource;
import haxe.ui.containers.TableView;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import kbe.components.WireMappingTable;
import kbe.KeyBoard.WireMapping;
import kbe.components.OneWayButton;
import kbe.components.properties.PropertyEditor;
import kbe.components.KeyboardContainer;
import kbe.components.KeyboardContainer.KeyButtonEvent;

private enum ColorMode {
	None;
	Conflicts;
	RainbowRows;
	RainbowColumns;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/new_property_dialog.xml"))
private class NewPropertyDialog extends Dialog {
	public function new() {
		super();
		title = "New property";
		buttons = DialogButton.OK | DialogButton.CANCEL;
	}

	public function result():String {
		return inputField.text;
	}
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/delete_property_dialog.xml"))
private class DeletePropertyDialog extends Dialog {
	public function new() {
		super();
		title = "Remove property";
		buttons = DialogButton.OK | DialogButton.CANCEL;
	}

	public function setProperties(properties:Array<String>) {
		var ds = new haxe.ui.data.ArrayDataSource();
		for (property in properties) {
			ds.add({value: property});
		}
		propertySelector.dataSource = ds;
	}

	public function result():String {
		return propertySelector.text;
	}
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/wiring_page.xml"))
class WiringPage extends HBox implements EditorPage {
	var keyboard:KeyBoard;
	var editor:Editor;
	var conflictingKeys = new Map<Int, Int>();
	var selectedBottomButtons:Array<OneWayButton> = [];
	var colorMode:ColorMode = Conflicts;

	var rows = 0;
	var columns = 0;

	public function new(?editor:Editor) {
		super();
		if (editor == null) {
			throw "can't call without editor";
		}
		this.editor = editor;
		this.keyboard = editor.getKeyboard();
		percentWidth = 100;
		percentHeight = 100;
		text = "Wiring";

		keyView.registerEvent(KeyboardContainer.BUTTON_CHANGED, onButtonChange);
		propEditor.onChange = onPropertyChange;
		keyView.formatButton = formatButton;
		keyView.selectionMode = MultiSelect;
		keyView.rectangleSelection = true;

		var ds = colorSelect.dataSource = new ListDataSource<Dynamic>();
		ds.add({value: "conflicts", mode: ColorMode.Conflicts});
		ds.add({value: "none", mode: ColorMode.None});
		ds.add({value: "rows", mode: ColorMode.RainbowRows});
		ds.add({value: "columns", mode: ColorMode.RainbowColumns});
	}

	public function init(editor:Editor) {
		this.editor = editor;
		reload();
	}

	@:bind(colorSelect, UIEvent.CHANGE)
	function onLayoutChanged(_:Null<Dynamic>) {
		var modeData = colorSelect.selectedItem;
		if (modeData != null) {
			colorMode = modeData.mode;
		} else {
			colorMode = Conflicts;
		}
		refreshFormatting();
	}

	function formatButton(button:KeyButton) {
		var key = button.key;
		button.text = '${StringTools.hex(key.row)} ${StringTools.hex(key.column)}';
		button.backgroundColor = null;
		if (colorMode == Conflicts) {
			var currentButton = keyView.activeButton;
			if (currentButton != button) {
				var row = currentButton != null ? currentButton.key.row : -1;
				var column = currentButton != null ? currentButton.key.column : -1;

				var color:thx.color.Rgb = null;
				if (!button.selected) {
					if (key.row == row) {
						color = 0xe0fde0;
					} else if (column == key.column) {
						color = 0xe0e0fd;
					}
				}
				if (conflictingKeys.exists(key.id)) {
					color = 0xffcc00;
				}
				if (key.row == row && column == key.column && button != keyView.activeButton) {
					color = 0xff6666;
				}
				if (color != null) {
					if (button.selected) {
						color = color.darker(0.2);
					}
					button.backgroundColor = color.toInt();
				}
			}
		} else if (colorMode == RainbowRows) {
			button.backgroundColor = KeyVisualizer.getIndexedColor(button.key.row, button.selected);
		} else if (colorMode == RainbowColumns) {
			button.backgroundColor = KeyVisualizer.getIndexedColor(button.key.column, button.selected);
		}
	}

	inline function getMatrixButton(x:Int, y:Int):OneWayButton {
		var component = matrixGrid.getComponentAt(x + y * columns);
		return cast component;
	}

	function refreshFormatting() {
		conflictingKeys.clear();
		var badKeys = editor.getConflictingWiring();
		labelConflicts.text = '${badKeys.length}';
		for (key in badKeys) {
			conflictingKeys.set(key.id, 0);
		}
		keyView.refreshFormatting();
		var uniqueUsed:Int = 0;
		for (y in 0...rows) {
			for (x in 0...columns) {
				var button = getMatrixButton(x, y);
				if (button != null) {
					button.backgroundColor = 0xffffff;
				};
			}
		}
		if (badKeys.length > 0) {
			labelUnassigned.text = '';
		} else {
			labelUnassigned.text = 'unassigned: ${rows * columns - keyboard.keys.length}';
		}

		for (key in keyboard.keys) {
			var button = getMatrixButton(key.column, key.row);
			if (button != null) {
				button.backgroundColor = null;
			}
		}
		for (key in badKeys) {
			var button = getMatrixButton(key.column, key.row);
			if (button != null) {
				button.backgroundColor = 0xff6666;
				if (button.selected) {
					button.backgroundColor = 0xd05656;
				}
			}
		}
	}

	function onPropertyChange(_) {
		var data = propEditor.source;
		var ids = [];
		var properties = [];
		var activeButtons = keyView.activeButtons();
		if (activeButtons.length == 0 || (data.row == null && data.column == null)) {
			return;
		}
		for (button in activeButtons) {
			ids.push(button.key.id);
			var buttonProp = new Map<String, Dynamic>();
			if (data.row != null) {
				buttonProp.set("row", data.row);
			}
			if (data.column != null) {
				buttonProp.set("column", data.column);
			}
			properties.push(buttonProp);
		}
		editor.modifyKeys(ids, properties);
		resizeMatrix();
		syncBottomSelection();
		refreshFormatting();
	}

	function syncBottomSelection() {
		for (button in selectedBottomButtons) {
			button.selected = false;
		}
		selectedBottomButtons = [];
		for (button in keyView.activeButtons()) {
			var bottomButton = getMatrixButton(button.key.column, button.key.row);
			if (bottomButton != null) {
				selectedBottomButtons.push(bottomButton);
				bottomButton.selected = true;
			}
		}
	}

	function getTopSelectionRowColumn():Dynamic {
		var value = {row: null, column: null};
		var activeButtons = keyView.activeButtons();
		if (activeButtons.length == 0) {
			return value;
		}
		value.row = activeButtons[0].key.row;
		value.column = activeButtons[0].key.column;
		for (button in activeButtons) {
			var key = button.key;
			if (key.row != value.row) {
				value.row = null;
			}
			if (key.column != value.column) {
				value.column = null;
			}
		}
		return value;
	}

	function onButtonChange(e:KeyButtonEvent) {
		propEditor.source = getTopSelectionRowColumn();
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

	function selectBottomButton(button:OneWayButton) {
		for (button in selectedBottomButtons) {
			button.selected = false;
		}
		selectedBottomButtons = [button];
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
				button.registerEvent(MouseEvent.CLICK, function(_) {
					selectBottomButton(button);
					selectTopButton(x, y);
					refreshFormatting();
				});
				matrixGrid.addComponent(button);
			}
		}
	}

	function refreshRowMapping() {
		var keyboard = editor.getKeyboard();
		rowTable.mappingSource = keyboard.rowMapping;
		colTable.mappingSource = keyboard.columnMapping;
	}

	public function reload() {
		keyboard = editor.getKeyboard();
		keyView.loadFromList(keyboard.keys);
		keyView.updateLayout();
		resizeMatrix();
		refreshFormatting();
		checkHasMatrixRows.selected = keyboard.rowMapping.hasWireColumn;
		rowCountEditor.number = keyboard.rowMapping.rows;
		columnCountEditor.number = keyboard.columnMapping.rows;
		refreshRowMapping();
	}

	@:bind(keyView, KeyboardEvent.KEY_UP)
	function onTopKeyDownU(e:KeyboardEvent) {
		if (e.keyCode == KC.R) {
			quickSetMode.selectedIndex = 1;
		} else if (e.keyCode == KC.C) {
			quickSetMode.selectedIndex = 2;
		}
		var number = null;
		if (e.keyCode >= KC.N0 && e.keyCode <= KC.N9) {
			number = e.keyCode - KC.N0;
		} else if (e.keyCode >= KC.NP_0 && e.keyCode <= KC.NP_9) {
			number = e.keyCode - KC.NP_0;
		}
		var quickMode = quickSetMode.selectedItem.id;
		if (number != null && (quickMode == "row" || quickMode == "column")) {
			if (quickMode == "row") {
				pRowEditor.number = number;
				pRowEditor.focus = true;
				e.cancel();
				pRowEditor.dispatch(new UIEvent(UIEvent.CHANGE));
			}
			if (quickMode == "column") {
				pColumnEditor.number = number;
				pColumnEditor.focus = true;
				e.cancel();
				pColumnEditor.dispatch(new UIEvent(UIEvent.CHANGE));
			}
		}
	}

	function updateWireMappingFromDescr(mapping:WireMapping, changes:kbe.components.WireMappingTable.SourceElement) {
		var row = changes.tRow;
		mapping.setMatrixRow(row, changes.tMatrixRow);
		for (field in Reflect.fields(changes)) {
			var column = mapping.getColumnIndex(field);
			if (column > -1) {
				mapping.setColumnValue(row, column, Reflect.getProperty(changes, field));
			}
		}
	}

	@:bind(checkHasMatrixRows, UIEvent.CHANGE)
	function hasMatrixRowsChanged(e:UIEvent) {
		var keyboard = editor.getKeyboard();
		var rows = keyboard.rowMapping.clone();
		var col = keyboard.columnMapping.clone();
		if (rows.hasWireColumn == checkHasMatrixRows.selected && col.hasWireColumn == checkHasMatrixRows.selected) {
			return; // prevent polluting history when triggered by page initialization
		}
		rows.hasWireColumn = checkHasMatrixRows.selected;
		col.hasWireColumn = checkHasMatrixRows.selected;
		editor.updateRowMapping(rows, col);

		refreshRowMapping();
	}

	@:bind(rowCountEditor, UIEvent.CHANGE)
	function onChangeRowCount(e:MouseEvent) {
		var keyboard = editor.getKeyboard();
		var rows = keyboard.rowMapping.clone();
		rows.resize(rowCountEditor.number);
		editor.updateRowMapping(rows, null);
		refreshRowMapping();
	}

	@:bind(columnCountEditor, UIEvent.CHANGE)
	function onChangeColumnCount(e:MouseEvent) {
		var keyboard = editor.getKeyboard();
		var columns = keyboard.columnMapping.clone();
		columns.resize(columnCountEditor.number);
		editor.updateRowMapping(null, columns);
		refreshRowMapping();
	}

	function handleWiringTableChange(e:ItemEvent, row:Bool) {
		if (e.sourceEvent.type == UIEvent.CHANGE && e.data != null) {
			var value = e.data;
			var keyboard = editor.getKeyboard();
			var rows = (row ? keyboard.rowMapping : keyboard.columnMapping).clone();
			updateWireMappingFromDescr(rows, value);
			if (row) {
				editor.updateRowMapping(rows);
			} else {
				editor.updateRowMapping(null, rows);
			}

			refreshRowMapping();
		}
	}

	@:bind(rowTable, ItemEvent.COMPONENT_EVENT)
	function onRowItemEvent(e:ItemEvent) {
		handleWiringTableChange(e, true);
	}

	@:bind(colTable, ItemEvent.COMPONENT_EVENT)
	function onColItemEvent(e:ItemEvent) {
		handleWiringTableChange(e, false);
	}

	@:bind(addProperty, MouseEvent.CLICK)
	function onAddPropertyClicked(e:MouseEvent) {
		var dialog = new NewPropertyDialog();
		dialog.width = 300;
		dialog.height = 150;
		dialog.onDialogClosed = onAddPropertyClosed;
		dialog.show();
	}

	function onAddPropertyClosed(e:DialogEvent) {
		if (e.button == DialogButton.OK) {
			var dialog = cast(e.target, NewPropertyDialog);
			var keyboard = editor.getKeyboard();
			var rows = keyboard.rowMapping.clone();
			var cols = keyboard.columnMapping.clone();

			var newColumn = dialog.result();
			rows.addColumn(newColumn);
			cols.addColumn(newColumn);
			editor.updateRowMapping(rows, cols);
			refreshRowMapping();
		}
	}

	@:bind(removeProperty, MouseEvent.CLICK)
	function onDeletePropertyClicked(e:MouseEvent) {
		var dialog = new DeletePropertyDialog();
		dialog.width = 300;
		dialog.height = 100;
		dialog.onDialogClosed = onDeletePropertyClosed;
		dialog.setProperties(editor.getKeyboard().rowMapping.columnNames);
		dialog.show();
	}

	function onDeletePropertyClosed(e:DialogEvent) {
		if (e.button == DialogButton.OK) {
			var dialog = cast(e.target, DeletePropertyDialog);
			var keyboard = editor.getKeyboard();
			var rows = keyboard.rowMapping.clone();
			var cols = keyboard.columnMapping.clone();

			var newColumn = dialog.result();
			rows.removeColumn(newColumn);
			cols.removeColumn(newColumn);
			editor.updateRowMapping(rows, cols);
			refreshRowMapping();
		}
	}

	@:bind(flipH, UIEvent.CHANGE)
	function flipHChange(_) {
		keyView.flipHorizontally = flipH.selected;
	}

	@:bind(flipV, UIEvent.CHANGE)
	function flipVChange(_) {
		keyView.flipVertically = flipV.selected;
	}
}
