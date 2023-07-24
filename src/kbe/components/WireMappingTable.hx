package kbe.components;

import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.core.Component;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.core.ItemRenderer;
import haxe.ui.components.Column;
import haxe.ui.containers.Header;
import haxe.ui.containers.TableView;
import haxe.ui.events.MouseEvent;
import haxe.ui.data.ArrayDataSource;
import kbe.KeyBoard.WireMapping;

typedef SourceElement = {
	tRow:Int,
	tMatrixRow:Int
};

class WireMappingTable extends TableView {
	public var mappingSource(default, set):Null<KeyBoard.WireMapping> = null;
	public var isRow(default, set):Bool = true;

	var ds = new ArrayDataSource<SourceElement>();
	var rowColumn:Column = null;
	var matrixRowColumn:Column = null;
	var initialized = false;

	public function new() {
		super();
		this.dataSource = ds;
		rowColumn = addColumn("tRow");
		matrixRowColumn = addColumn("tMatrixRow");

		matrixRowColumn.width = 80;
		this.virtual = true;
		isRow = true; // trigger setter
		this.selectionMode = haxe.ui.constants.SelectionMode.MULTIPLE_CLICK_MODIFIER_KEY;
	}

	public function set_isRow(v:Bool):Bool {
		isRow = v;
		if (isRow) {
			rowColumn.text = "row";
			matrixRowColumn.text = "logic row";
		} else {
			rowColumn.text = "col";
			matrixRowColumn.text = "logic col";
		}
		return v;
	}

	public function set_mappingSource(value:WireMapping):WireMapping {
		this.mappingSource = value;
		reloadFromSource();
		return value;
	}

	public function reloadColumnsFromSource() {
		// ds.clear();
		header.removeComponent(rowColumn, false);
		if (matrixRowColumn.parentComponent == header) {
			header.removeComponent(matrixRowColumn, false);
		}
		this.clearContents(true);
		var r = itemRenderer;

		header.addComponent(rowColumn);
		var rowLabel:Component = r.findComponent("tRow");
		rowLabel.parentComponent.verticalAlign = "center";

		if (mappingSource != null) {
			if (mappingSource.hasWireColumn) {
				header.addComponent(matrixRowColumn);

				var foo:Component = r.findComponent("tMatrixRow");
				var renderer:ItemRenderer = cast foo.parentComponent;
				renderer.removeAllComponents();
				var input:NumberStepper = new NumberStepper();
				input.percentWidth = 90;
				input.max = 1024;
				input.min = 0;

				input.id = "tMatrixRow";
				renderer.addComponent(input);
			}
			for (name in mappingSource.columnNames) {
				var column = addColumn(name);
				column.text = name;
				column.id = name;
				column.width = 60;
				var foo:Component = r.findComponent(name);
				var renderer:ItemRenderer = cast foo.parentComponent;
				renderer.removeAllComponents();

				var input = new TextField();
				input.id = name;
				input.width = 50;
				renderer.addComponent(input);
			}
		}
	}

	public function reloadDataFromSource() {
		ds.allowCallbacks = false;
		ds.clear();
		if (mappingSource != null) {
			for (i in 0...mappingSource.rows) {
				var item:SourceElement = {
					tRow: i,
					tMatrixRow: mappingSource.getMatrixRow(i)
				};
				var columnIndex = 0;
				for (name in mappingSource.columnNames) {
					var v = mappingSource.getColumnValue(i, columnIndex);
					if (v == null) {
						v = "";
					}
					Reflect.setField(item, name, v);
					columnIndex += 1;
				}
				ds.add(item);
			}
		}
		ds.allowCallbacks = true;
	}

	public function reloadFromSource() {
		reloadColumnsFromSource();
		reloadDataFromSource();
	}
}
