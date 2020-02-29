package kbe;

import haxe.ui.data.ArrayDataSource;
import kbe.QMKLayoutMacro.ExportLayoutConfig;
import kbe.KeyBoard.KeyboardLayout;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.data.ListDataSource;

@:build(haxe.ui.macros.ComponentMacros.build("assets/export_layout_dialog.xml"))
class ExportLayoutDialog extends Dialog {
	public var onAccept:Null<(ExportLayoutConfig) -> Void> = null;

	private var keyboard:KeyBoard;

	public function new(?keyboard:KeyBoard) {
		if (keyboard == null) {
			throw "keyboard not set";
		}
		this.keyboard = keyboard;
		super();
		title = "Export layout";
		buttons = DialogButton.OK | DialogButton.CANCEL;
		onDialogClosed = onClosed;
		this.width = 300;
		this.height = 300;

		var ds = new ArrayDataSource();
		for (layout in keyboard.layouts) {
			ds.add({value: layout.name, layout: layout});
		}
		layoutSelection.dataSource = ds;
		layoutSelection.dataSource;

		exportCountAll.onChange = onCountChange;
		exportCountSingle.onChange = onCountChange;
		exportCountSubset.onChange = onCountChange;
	}

	function onClosed(e:DialogEvent) {
		if (e.button == DialogButton.OK && onAccept != null) {
			onAccept(result());
		}
	}

	function onCountChange(_) {
		if (exportCountAll.selected) {
			layoutSelectionLabel.hidden = true;
			layoutSelection.hidden = true;
		} else {
			layoutSelectionLabel.hidden = false;
			layoutSelection.hidden = false;
			if (exportCountSingle.selected) {
				layoutSelection.selectionMode = ONE_ITEM;
			}
			if (exportCountSubset.selected) {
				layoutSelection.selectionMode = MULTIPLE_CLICK_MODIFIER_KEY;
			}
		}
	}

	public function result():ExportLayoutConfig {
		var layouts:Null<Array<KeyboardLayout>> = null;
		if (!exportCountAll.selected) {
			layouts = layoutSelection.selectedItems.map(item -> item.layout);
		}
		return {
			layouts: layouts,
			unmappedKey: unmappedKeyString.value,
			argName: (argNameType.selectedItem.type == "LayoutRows" ? LayoutRows : MatrixRows)
		};
	}
}
