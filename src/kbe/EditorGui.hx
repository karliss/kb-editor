package kbe;

import haxe.io.Bytes;
import haxe.ui.data.ArrayDataSource;
import kbe.CSVFormat.CSVExporter;
import kbe.KBLEFormat.KBLEImporter;
import kbe.CSVFormat.CSVImporter;
import kbe.Exporter.Importer;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
#if js
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

		fillFormats();
	}

	function reloadPages() {
		for (page in pages) {
			page.reload();
		}
	}

	function fillFormats() {
		var importers = [new CSVImporter(), new KBLEImporter()];
		this.importFormat.dataSource = new ArrayDataSource();
		for (importer in importers) {
			importFormat.dataSource.add(importer);
		}

		var exporters = [new CSVExporter(), new TestExporter()];
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
		FileSaver.saveAs(new Blob([new Uint8Array(intArray)]), exporter.fileName(), true); // TODO PASS NAME
		#end
	}

	function onClickImport(_):Void {
		var importer = importFormat.selectedItem;
		// TODO: remove if js
		#if js
		FileOpener.tryToOpenFile(function(bytes, names) {
			var result = importer.convert(bytes[0], names[0]);
			this.keyboard = result;
			editor.setKeyboard(keyboard);
			reloadPages();
		});
		#end
	}

	function onPageChange(_) {
		var page:EditorPage = cast tabList.selectedPage;
		page.reload();
	}
}
