package kbe;

import kbe.KeyBoard.RowColNull;
import kbe.KeyVisualizer.KeyLabelMode;
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
	var showLogicalMatrix = false;

	public function new(?editor:Editor) {
		if (editor == null) {
			throw "can't call without editor";
		}
		this.editor = editor;
		this.keyboard = editor.getKeyboard();
		super();
		percentWidth = 100;
		percentHeight = 100;
		text = "Wiring";

		propEditor.onChange = onPropertyChange;
		keyView.formatButton = formatButton;
		keyView.selectionMode = MultiSelect;
		keyView.rectangleSelection = true;

		var ds = colorSelect.dataSource = new ListDataSource<Dynamic>();
		ds.add({value: "conflicts", mode: ColorMode.Conflicts});
		ds.add({value: "none", mode: ColorMode.None});
		ds.add({value: "rows", mode: ColorMode.RainbowRows});
		ds.add({value: "columns", mode: ColorMode.RainbowColumns});

		layoutLabelSelection.dataSource = new ListDataSource<Dynamic>();

		var initialLabelMode = -1;
		var i = 0;
		for (mode in KeyVisualizer.COMMON_LABEL_MODES) {
			layoutLabelSelection.dataSource.add(mode);
			if (mode.mode == KeyLabelMode.RowColumn) {
				initialLabelMode = i;
			}
			i++;
		}
		layoutLabelSelection.selectedIndex = initialLabelMode;
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

	@:bind(layoutLabelSelection, UIEvent.CHANGE)
	function onLayoutLabelModeChanged(e:UIEvent) {
		keyView.refreshFormatting();
	}

	function formatButton(button:KeyButton) {
		var key = button.key;
		KeyVisualizer.updateButtonLabel(keyboard, button, layoutLabelSelection.selectedItem.mode);
		button.backgroundColor = null;
		if (colorMode == Conflicts) {
			var currentButton = keyView.activeButton;
			if (currentButton != button) {
				var row = currentButton != null ? currentButton.key.row : -1;
				var column = currentButton != null ? currentButton.key.column : -1;

				var color:Null<thx.color.Rgb> = null;
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

	function getKeyMatrixButton(key:Key):OneWayButton {
		var pos = keyboard.getKeyPos(showLogicalMatrix, key);
		return getMatrixButton(pos.col, pos.row);
	}

	inline function getMatrixButton(x:Int, y:Int):OneWayButton {
		var component = matrixGrid.getComponentAt(x + y * columns);
		return cast component;
	}

	function refreshFormatting() {
		conflictingKeys.clear();
		var badKeys = editor.getConflictingWiring(showLogicalMatrix);
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
			var button = getKeyMatrixButton(key);
			if (button != null) {
				button.backgroundColor = null;
			}
		}
		for (key in badKeys) {
			var button = getKeyMatrixButton(key);
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
		if (data == null) {
			return;
		}
		var ids = [];
		var properties = [];
		var activeButtons = keyView.activeButtons();
		var row = data.get("row");
		var column = data.get("col");
		if (activeButtons.length == 0 || (row == null && column == null)) {
			return;
		}
		for (button in activeButtons) {
			ids.push(button.key.id);
			var buttonProp = new Map<String, Dynamic>();
			if (row != null) {
				buttonProp.set("row", row);
			}
			if (column != null) {
				buttonProp.set("column", column);
			}
			properties.push(buttonProp);
		}
		editor.modifyKeys(ids, properties);
		refreshBottom();
		refreshFormatting();
	}

	inline function refreshBottom() {
		resizeMatrix();
		syncBottomSelection();
	}

	function syncBottomSelection() {
		for (button in selectedBottomButtons) {
			button.selected = false;
		}
		selectedBottomButtons = [];
		for (button in keyView.activeButtons()) {
			var bottomButton = getKeyMatrixButton(button.key);
			if (bottomButton != null) {
				selectedBottomButtons.push(bottomButton);
				bottomButton.selected = true;
			}
		}
	}

	function getTopSelectionRowColumn():RowColNull {
		var value = {row: null, col: null};
		var activeButtons = keyView.activeButtons();
		if (activeButtons.length == 0) {
			return value;
		}
		value.row = activeButtons[0].key.row;
		value.col = activeButtons[0].key.column;
		for (button in activeButtons) {
			var key = button.key;
			if (key.row != value.row) {
				value.row = null;
			}
			if (key.column != value.col) {
				value.col = null;
			}
		}
		return value;
	}

	@:bind(keyView, KeyboardContainer.BUTTON_CHANGED)
	function onButtonChange(e:KeyButtonEvent) {
		var data = getTopSelectionRowColumn();
		propEditor.source = ["row" => data.row, "col" => data.col];
		btnAutoIncrementColumns.disabled = keyView.activeButtons().length <= 1;
		syncBottomSelection();
		refreshFormatting();
	}

	function selectTopButton(x:Int, y:Int) {
		for (key in keyboard.keys) {
			var pos = keyboard.getKeyPos(showLogicalMatrix, key);
			if (pos.row == y && pos.col == x) {
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
		var need = showLogicalMatrix ? keyboard.getMatrixSize() : keyboard.getWiringMatrixSize();
		columnsNeed = need.col;
		rowsNeed = need.row;

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
		btnSwap2Rows.disabled = rowTable.selectedIndices.length != 2;
		btnSwap2Columns.disabled = colTable.selectedIndices.length != 2;
	}

	@:bind(keyView, KeyboardEvent.KEY_UP)
	function onTopKeyDown(e:KeyboardEvent) {
		if (e.keyCode == KC.R) {
			quickSetMode.selectedIndex = 1;
		} else if (e.keyCode == KC.C) {
			quickSetMode.selectedIndex = 2;
		}
		var number:Null<Int> = null;
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
	function onHasMatrixRowsChange(e:UIEvent) {
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
			if (checkHasMatrixRows.selected) {
				refreshBottom();
				refreshFormatting();
			}
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

	@:bind(keyViewScale, UIEvent.CHANGE)
	function keyViewScaleChange(e:UIEvent) {
		this.keyView.scale = keyViewScale.number;
	}

	@:bind(resizeToKeyboard, MouseEvent.CLICK)
	function onResizeToKeyboard(_) {
		editor.resizeWiringToKeyboard();
		refreshRowMapping();
	}

	@:bind(rowTable, UIEvent.CHANGE)
	function onRowSelectionChange(e:UIEvent) {
		var selectedRows:Array<Int> = rowTable.selectedItems.map(descr -> descr.tRow);
		var selection = keyView.buttons.filter(button -> selectedRows.indexOf(button.key.row) > -1);
		keyView.selectButtons([for (button in selection) button]);
		btnSwap2Rows.disabled = selectedRows.length != 2;
	};

	@:bind(colTable, UIEvent.CHANGE)
	function onColumnSelectionChange(e:UIEvent) {
		var selectedColumns:Array<Int> = colTable.selectedItems.map(descr -> descr.tRow);
		var selection = keyView.buttons.filter(button -> selectedColumns.indexOf(button.key.column) > -1);
		keyView.selectButtons([for (button in selection) button]);
		btnSwap2Columns.disabled = selectedColumns.length != 2;
	};

	@:bind(btnSwapWiringRowsColumns, MouseEvent.CLICK)
	function onBtnSwapWiringRowsColumns(e:MouseEvent) {
		editor.swapWiringRowColumnAssignment();
		reload();
	}

	@:bind(btnSwapKeyRowsProperties, MouseEvent.CLICK)
	function onBtnSwapKeyRowsProperties(e:MouseEvent) {
		editor.swapWiringRowColumnProperties();
		reload();
	}

	@:bind(btnSwap2Rows, MouseEvent.CLICK)
	function swap2Rows(e:MouseEvent) {
		var selection = rowTable.selectedIndices;
		if (selection.length == 2) {
			editor.swapTwoWiringRows(true, selection[0], selection[1]);
			refreshBottom();
			refreshFormatting();
		}
	}

	@:bind(btnSwap2Columns, MouseEvent.CLICK)
	function swap2Columns(e:MouseEvent) {
		var selection = colTable.selectedIndices;
		if (selection.length == 2) {
			editor.swapTwoWiringRows(false, selection[0], selection[1]);
			refreshBottom();
			refreshFormatting();
		}
	}

	@:bind(gridModeSelection, UIEvent.CHANGE)
	function gridModeChange(e:UIEvent) {
		if (gridModeSelection.selectedItem.data == "logical") {
			showLogicalMatrix = true;
		} else {
			showLogicalMatrix = false;
		}
		refreshBottom();
		refreshFormatting();
	}

	@:bind(btnAutoIncrementColumns, MouseEvent.CLICK)
	function onAutoIncrementColumns(_) {
		var selectedKeys = keyView.selectedKeys();
		if (selectedKeys.length > 1) {
			editor.autoIncrementWiringColumns(selectedKeys);
			reload();
		}
	}
}
