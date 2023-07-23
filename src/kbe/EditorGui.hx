package kbe;

import haxe.ui.containers.VBox;
import kbe.QMKLayoutMacro.QMKLayoutMacroExporter;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.Grid;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.Toolkit;
import haxe.ui.events.MouseEvent;
import haxe.io.Bytes;
import haxe.ui.data.ArrayDataSource;
import kbe.Exporter.Importer;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
import kbe.FormatManager;
#if js
import js.Browser;
import js.html.Blob;
#end
import kbe.FileOpener;

@:build(haxe.ui.macros.ComponentMacros.build("assets/editor.xml"))
class EditorGui extends VBox {
	var pageMechanical:Null<MechanicalPage> = null;
	var pageWiring:Null<WiringPage> = null;
	var editor:Editor = new Editor(new KeyBoard());
	var pages = new Array<EditorPage>();

	public function new() {
		super();
		pageMechanical = new MechanicalPage(editor);
		tabList.addComponent(pageMechanical);
		pages.push(pageMechanical);

		pageWiring = new WiringPage(editor);
		tabList.addComponent(pageWiring);
		pages.push(pageWiring);

		var layoutPage:LayoutPage = new LayoutPage(editor);
		tabList.addComponent(layoutPage);
		pages.push(layoutPage);

		for (page in pages) {
			page.init(editor);
		}

		percentWidth = 100;
		percentHeight = 100;

		reloadPages();

		tabList.onChange = onPageChange;

		this.undoButton.onClick = _ -> undo();
		this.undoMenuButton.onClick = _ -> undo();
		this.redoButton.onClick = _ -> redo();
		this.redoMenuButton.onClick = _ -> redo();
		exportQMKLayoutMacros.onClick = onExportQMKLayoutMacros;

		fillFormats();
		#if js
		bindJsKeyShortcuts();
		#end
	}

	function undo() {
		editor.undoBuffer.undo();
		reloadCurrentPage();
	}

	function redo() {
		editor.undoBuffer.redo();
		reloadCurrentPage();
	}

	#if js
	function bindJsKeyShortcuts() {
		var document = Browser.document;
		document.addEventListener("keydown", (event:js.html.KeyboardEvent) -> {
			if (event.ctrlKey) {
				switch (event.key) {
					case "z":
						undo();
					case "y":
						redo();
					default:
				}
			}
		});
	}
	#end

	function reloadPages() {
		for (page in pages) {
			page.reload();
		}
	}

	function reloadCurrentPage() {
		var page:EditorPage = cast tabList.selectedPage;
		if (page != null) {
			page.reload();
		}
	}

	function fillFormats() {
		var importers = FormatManager.getImporters();
		importSubmenu.removeAllComponents();
		for (importer in importers) {
			var item = new MenuItem();
			item.text = importer.value;
			item.percentWidth = 100;
			item.onClick = (_) -> {
				onClickImport(importer);
			};
			importSubmenu.addComponent(item);
		}

		var exporters = FormatManager.getExporters();
		for (exporter in exporters) {
			var item = new MenuItem();
			item.text = exporter.value;
			item.onClick = (_) -> {
				onClickExport(exporter);
			}
			exportSubmenu.addComponent(item);
		}
	}

	function onClickExport(exporter:Exporter):Void {
		var result:Bytes;
		try {
			result = exporter.convert(editor.getKeyboard());
		} catch (e:Dynamic) {
			Dialogs.messageBox('Export converter error $e', null, MessageBoxType.TYPE_ERROR);
			return;
		}

		FileAccess.saveFile(result, exporter.fileName());
	}

	function onClickImport(importer:Importer):Void {
		// TODO: remove if js
		#if js
		FileOpener.tryToOpenFile(function(bytes, names) {
			var result:KeyBoard = null;
			try {
				result = importer.convert(bytes[0], names[0]);
			} catch (e:Dynamic) {
				Dialogs.messageBox('Import error $e', null, MessageBoxType.TYPE_ERROR);
				return;
			}
			var keyboard = result;
			editor.setKeyboard(keyboard);
			editor.undoBuffer.clear();
			reloadPages();
		});
		#end
	}

	function onExportQMKLayoutMacros(_) {
		var keyboard = editor.getKeyboard();
		var dialog = new ExportLayoutDialog(keyboard);
		dialog.onAccept = (config) -> {
			var result:Bytes;
			var exporter = new QMKLayoutMacroExporter(false);
			try {
				result = exporter.convertWithConfig(keyboard, config);
			} catch (e:Dynamic) {
				Dialogs.messageBox('Export converter error $e', null, MessageBoxType.TYPE_ERROR);
				return;
			}
			FileAccess.saveFile(result, exporter.fileName());
		};
		dialog.show();
	}

	function onPageChange(_) {
		reloadCurrentPage();
	}
}
