package kbe.components;

import haxe.ui.constants.ScrollMode;
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
	public var mappingSource(default, set):KeyBoard.WireMapping = null;
	public var isRow(default, set):Bool;

	var ds = new ArrayDataSource<SourceElement>();
	var rowColumn = new Column();
	var matrixRowColumn = new Column();
	var header = new Header();

	public function new() {
		super();
		this.dataSource = ds;
		rowColumn.id = "tRow";
		matrixRowColumn.id = "tMatrixRow";

		isRow = true;

		matrixRowColumn.width = 90;
		this.virtual = true;
		addComponent(header);
	}

	public function set_isRow(v:Bool):Bool {
		isRow = v;
		if (isRow) {
			rowColumn.text = "row";
			matrixRowColumn.text = "matrix row";
		} else {
			rowColumn.text = "col";
			matrixRowColumn.text = "matrix col";
		}
		return v;
	}

	public function set_mappingSource(value:WireMapping):WireMapping {
		this.mappingSource = value;
		reloadFromSource();
		return value;
	}

	public function reloadColumnsFromSource() {
		ds.clear();
		while (header.childComponents.length > 0) {
			header.removeComponentAt(header.childComponents.length - 1, false, false);
		}
		itemRenderer = null;
		var renderers = [];
		header.addComponent(rowColumn);
		var rowLabel = new Label();
		rowLabel.id = "tRow";
		var r = new ItemRenderer();
		r.addComponent(rowLabel);
		renderers.push(r);
		if (mappingSource != null) {
			if (mappingSource.hasWireColumn) {
				header.addComponent(matrixRowColumn);
				var renderer = new ItemRenderer();
				var input = new IntegerEditor();
				input.maximum = 1024;
				input.width = 60;

				input.id = "tMatrixRow";
				renderer.addComponent(input);
				renderers.push(renderer);
			}
			for (name in mappingSource.columnNames) {
				var column = new Column();
				column.text = name;
				column.id = name;
				column.width = 50;
				header.addComponent(column);
				var input = new TextField();
				input.id = name;
				input.width = 40;
				var renderer = new ItemRenderer();
				renderer.addComponent(input);
				renderers.push(renderer);
			}
		}
		this.addComponent(header);
		for (renderer in renderers) {
			addComponent(renderer);
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
