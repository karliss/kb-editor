package kbe;

import kbe.Exporter;

class FormatManager {
	public static function getImporters():Array<Exporter.Importer> {
		return [
			new CSVFormat.CSVImporter(),
			new KBLEFormat.KBLEImporter(),
			new KBLEFormat.KBLERawImporter(),
			new QMKInfoJson.QMKInfoJsonImporter()
		];
	}

	public static function getExporters():Array<Exporter> {
		return [new CSVFormat.CSVExporter(), new TestExporter()];
	}
}
