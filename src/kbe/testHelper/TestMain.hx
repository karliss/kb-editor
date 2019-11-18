package kbe.testHelper;

import utest.Runner;
import utest.ui.Report;

class TestMain {
	public function new() {}

	public static function main() {
		var runner = new Runner();
		runner.addCases(kbe.tests);
		Report.create(runner);
		runner.run();
	}
}
