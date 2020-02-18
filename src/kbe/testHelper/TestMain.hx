package kbe.testHelper;

import utest.ui.text.PrintReport;
import utest.ui.common.PackageResult;
import utest.Runner;
import utest.ui.Report;

class NoExitPrintReport extends utest.ui.text.PrintReport {
	override function complete(result:PackageResult) {
		if (result.stats.isOk) {
			this.result = result;
			if (handler != null)
				handler(this);
		} else {
			super.complete(result);
		}
	}
}

class TestMain {
	public function new() {}

	public static function main() {
		var runner = new Runner();
		runner.addCases(kbe.tests);
		#if TEST_EVAL_NOEXIT
		var reporter = new NoExitPrintReport(runner);
		asdf
		#else
		Report.create(runner);
		#end
		runner.run();
	}
}
