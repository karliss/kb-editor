package kbe.testHelper;

import kbe.UndoBuffer;

enum Action {
	Set(v:Int);
	Add(v:Int);
}

class TestState implements Clonable<TestState> {
	public var v:Int;

	public function new(?v:Int) {
		this.v = 0;
		if (v != null) {
			this.v = v;
		}
	}

	public function clone():TestState {
		return new TestState(this.v);
	}
}

class TestUndoExecutor implements kbe.UndoBuffer.UndoExecutor<TestState, Action> {
	@:isVar public var state(get, set):TestState = new TestState(0);
	public var getCount:Int = 0;
	public var setCount:Int = 0;

	public function new() {}

	public function resetCounts() {
		getCount = 0;
		setCount = 0;
	}

	function get_state():TestState {
		return state;
	}

	function set_state(s:TestState):TestState {
		state = s;
		return state;
	}

	public function applyAction(action:Action) {
		switch (action) {
			case Set(v):
				this.state.v = v;
			case Add(v):
				this.state.v += v;
		}
	}
}
