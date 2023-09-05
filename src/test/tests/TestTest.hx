package kbe.tests;

import utest.Assert;

class TestTest extends utest.Test {
	var field:String;

	// synchronous setup
	public function setup() {
		field = "some";
	}

	function testFieldIsSome() {
		Assert.equals("some", field);
	}

	function specField() {
		field.charAt(0) == 's';
		field.length > 3;
	}
}
