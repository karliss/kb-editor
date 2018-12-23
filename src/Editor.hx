package ;

import haxe.ui.core.Component;
import haxe.ui.components.Button;

import js.html.Blob;
import js.html.FileSaver;
import js.html.Uint8Array;

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
    }

    function onClickExport(_): Void {
        var exporter = new TestExporter();
        var result = exporter.convert(keyboard);

        var intArray = new Array<Int>();
        for (i in 0 ... result.length) {
            intArray.push(result.get(i));
        }
        FileSaver.saveAs(new Blob([new Uint8Array(intArray)]), null, false);
    }
}
