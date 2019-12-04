package kbe;

interface Clonable<T> {
	function clone():T;
}

interface UndoExecutor<S:Clonable<S>, A> {
	public var state(get, set):S;
	function applyAction(a:A):Dynamic;
}

class UndoBuffer<S:Clonable<S>, A> {
	var executor:UndoExecutor<S, A>;
	var stateList = new Array<S>();
	var actionList = new Array<A>();
	var redoActions = new Array<A>();

	public function new(executor:UndoExecutor<S, A>) {
		this.executor = executor;
	}

	public var undoCount(get, null):Int;

	function get_undoCount():Int {
		return actionList.length;
	}

	public var redoCount(get, null):Int;

	function get_redoCount():Int {
		return redoActions.length;
	}

	function pushStateInternal(a:A, redo = false) {
		if (!redo) {
			redoActions = [];
		}
		stateList.push(executor.state.clone());
		actionList.push(a);
	}

	function runActionInternal(a:A, redo = false):Dynamic {
		pushStateInternal(a, redo);
		return executor.applyAction(a);
	}

	public function pushState(a:A) {
		pushStateInternal(a);
	}

	public function runAction(a:A):Dynamic {
		return runActionInternal(a);
	}

	public function undo():Bool {
		if (undoCount <= 0) {
			return false;
		}
		redoActions.push(actionList.pop());
		executor.state = stateList.pop();
		return true;
	}

	public function redo() {
		var action = redoActions.pop();
		if (action != null) {
			runActionInternal(action, true);
			return true;
		}
		return false;
	}

	public function clear() {
		redoActions = [];
		actionList = [];
		stateList = [];
	}
}
