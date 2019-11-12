package;

import haxe.io.Bytes;
import haxe.ui.data.ArrayDataSource;
import CSVFormat.CSVExporter;
import KBLEFormat.KBLEImporter;
import CSVFormat.CSVImporter;
import Exporter.Importer;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
#if js
import js.html.Blob;
import js.html.FileSaver;
import js.lib.Uint8Array;
#end
import FileOpener;

@:build(haxe.ui.macros.ComponentMacros.build("assets/editor.xml"))
class Editor extends Component {
	var pageMechanical:MechanicalPage;
	var pageWiring = new WiringPage();
	var keyboard = new KeyBoard();

	public function new() {
		super();
		percentWidth = 100;
		percentHeight = 100;

		pageMechanical = new MechanicalPage();
		pageMechanical.setKeyboard(keyboard);
		tabList.addComponent(pageMechanical);
		pageWiring.setKeyboard(keyboard);
		tabList.addComponent(pageWiring);

		this.exportButton.onClick = onClickExport;
		this.importButton.onClick = onClickImport;

		tabList.onChange = onPageChange;

		fillFormats();
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
		FileSaver.saveAs(new Blob([new Uint8Array(intArray)]), null, false);
		#end
	}

	function onClickImport(_):Void {
		var importer = importFormat.selectedItem;
		// TODO: remove if js
		#if js
		FileOpener.tryToOpenFile(function(bytes, names) {
			var result = importer.convert(bytes[0], names[0]);
			this.keyboard = result;
			pageMechanical.setKeyboard(keyboard);
			pageWiring.setKeyboard(keyboard);
		});
		#end
	}

	function onPageChange(_) {
		if (tabList.selectedPage == pageMechanical) {
			pageMechanical.reload();
		} else if (tabList.selectedPage == pageWiring) {
			pageWiring.reload();
		}
	}
}
