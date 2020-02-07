package kbe;

import haxe.ui.events.KeyboardEvent;
import haxe.io.Bytes;
import haxe.ui.data.ArrayDataSource;
import kbe.Exporter.Importer;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
import kbe.FormatManager;
#if js
import js.Browser;
import js.html.Blob;
import js.html.FileSaver;
import js.lib.Uint8Array;
#end
import kbe.FileOpener;

@:build(haxe.ui.macros.ComponentMacros.build("assets/editor.xml"))
class EditorGui extends Component {
	var pageMechanical:MechanicalPage;
	var pageWiring:WiringPage;
	var keyboard = new KeyBoard();
	var editor:Editor;
	var pages = new Array<EditorPage>();

	public function new() {
		super();
		editor = new Editor(keyboard);
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

		this.exportButton.onClick = onClickExport;
		this.importButton.onClick = onClickImport;

		tabList.onChange = onPageChange;

		this.undoButton.onClick = _ -> undo();
		this.redoButton.onClick = _ -> redo();

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
		page.reload();
	}

	function fillFormats() {
		var importers = FormatManager.getImporters();
		this.importFormat.dataSource = new ArrayDataSource();
		for (importer in importers) {
			importFormat.dataSource.add(importer);
		}

		var exporters = FormatManager.getExporters();
		exportFormat.dataSource = new ArrayDataSource();
		for (exporter in exporters) {
			exportFormat.dataSource.add(exporter);
		}
	}

	function onClickExport(_):Void {
		var exporter = exportFormat.selectedItem;
		var result:Bytes = exporter.convert(keyboard);

		#if js
		var intArray = new Array<Int>();
		for (i in 0...result.length) {
			intArray.push(result.get(i));
		}
		FileSaver.saveAs(new Blob([new Uint8Array(intArray)]), exporter.fileName(), true);
		#end
	}

	function onClickImport(_):Void {
		var importer = importFormat.selectedItem;
		if (importer == null) {
			return;
		}
		// TODO: remove if js
		#if js
		FileOpener.tryToOpenFile(function(bytes, names) {
			var result = importer.convert(bytes[0], names[0]);
			this.keyboard = result;
			editor.setKeyboard(keyboard);
			editor.undoBuffer.clear();
			reloadPages();
		});
		#end
	}

	function onPageChange(_) {
		reloadCurrentPage();
	}
}
