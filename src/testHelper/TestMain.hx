package testHelper;

import utest.Runner;
import utest.ui.Report;

class TestMain {
	public function new() {}

	public static function main() {
		var runner = new Runner();
		runner.addCases(tests);
		Report.create(runner);
		runner.run();
	}
}
