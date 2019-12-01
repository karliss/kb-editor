package kbe.tests;

import utest.Assert;
import kbe.testHelper.TestUndoExecutor;
import kbe.testHelper.TestUndoExecutor.Action;
import kbe.testHelper.TestUndoExecutor.TestState;

class UndoBufferTest extends utest.Test {
	function testTestExecutor() {
		var executor = new TestUndoExecutor();
		Assert.equals(0, executor.state.v);
		executor.state = new TestState(4);
		Assert.equals(4, executor.state.v);
		executor.applyAction(Action.Set(5));
		Assert.equals(5, executor.state.v);
		executor.applyAction(Action.Add(-10));
		Assert.equals(-5, executor.state.v);

		Assert.notEquals(executor.state, executor.state.clone());
	}

	function testCount() {
		var executor = new TestUndoExecutor();
		var undo = new UndoBuffer<TestState, Action>(executor);
		Assert.equals(0, undo.undoCount);
		Assert.equals(0, undo.redoCount);
		undo.runAction(Action.Set(5));
		Assert.equals(1, undo.undoCount);
		Assert.equals(0, undo.redoCount);
		undo.runAction(Action.Set(6));
		undo.runAction(Action.Set(7));
		Assert.equals(3, undo.undoCount);
		Assert.equals(0, undo.redoCount);
		undo.undo();
		Assert.equals(2, undo.undoCount);
		Assert.equals(1, undo.redoCount);
		undo.redo();
		Assert.equals(3, undo.undoCount);
		Assert.equals(0, undo.redoCount);
	}

	function testEnd() {
		var executor = new TestUndoExecutor();
		var undo = new UndoBuffer<TestState, Action>(executor);
		Assert.isFalse(undo.undo());
		Assert.isFalse(undo.redo());
		for (i in 0...5) {
			undo.runAction(Action.Add(3));
		}
		for (i in 0...10) {
			if (i < 5) {
				Assert.isTrue(undo.undo());
				Assert.equals(3 * 5 - (i + 1) * 3, executor.state.v);
			} else {
				Assert.isFalse(undo.undo());
				Assert.equals(0, executor.state.v);
			}
		}
		for (i in 0...10) {
			if (i < 5) {
				Assert.isTrue(undo.redo());
				Assert.equals((i + 1) * 3, executor.state.v);
			} else {
				Assert.isFalse(undo.redo());
				Assert.equals(15, executor.state.v);
			}
		}
	}
}
