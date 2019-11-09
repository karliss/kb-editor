package;

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
	var keyboard = new KeyBoard();

	public function new() {
		super();
		percentWidth = 100;
		percentHeight = 100;

		pageMechanical = new MechanicalPage();
		pageMechanical.setKeyboard(keyboard);
		tabList.addComponent(pageMechanical);

		this.exportButton.onClick = onClickExport;
		this.importButton.onClick = onClickImport;
	}

	function onClickExport(_):Void {
		var exporter = new TestExporter();
		var result = exporter.convert(keyboard);

		var intArray = new Array<Int>();
		for (i in 0...result.length) {
			intArray.push(result.get(i));
		}
		#if js
		FileSaver.saveAs(new Blob([new Uint8Array(intArray)]), null, false);
		#end
	}

	function onClickImport(_):Void {
		var importer = new TestImporter();
		//TODO: remove if js
		#if js
		FileOpener.tryToOpenFile(function(bytes, names) {
			var result = importer.convert(bytes[0], names[0]);
			this.keyboard = result;
			pageMechanical.setKeyboard(keyboard);
		});
		#end
	}
}
