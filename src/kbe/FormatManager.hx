package kbe;

import kbe.QMKLayoutMacro.QMKLayoutMacroExporter;
import kbe.Exporter;

class FormatManager {
	public static function getImporters():Array<Exporter.Importer> {
		return [
			new CSVFormat.CSVImporter(),
			new KBLEFormat.KBLEImporter(),
			new KBLEFormat.KBLERawImporter(),
			new QMKInfoJson.QMKInfoJsonImporter(),
			new TKBEditorFormat.TKBEImporter()
		];
	}

	public static function getExporters():Array<Exporter> {
		return [
			new CSVFormat.CSVExporter(),
			new TKBEditorFormat.TKBEExporter(),
			new QMKLayoutMacroExporter(true),
			new QMKKeymapJsonTemplate.QMKKeymapJsonTemplateExporter(true),
			new QMKInfoJson.QMKInfoJsonExporter(),
			new TestExporter()
		];
	}
}
