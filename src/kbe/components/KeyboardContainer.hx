package kbe.components;

import haxe.ui.geom.Rectangle;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.constants.ScrollMode;

typedef Point = {x:Float, y:Float}

enum SelectionCommand {
	Set;
	Add;
	Toggle;
	Remove;
}

enum SelectionMode {
	SingleSet;
	MultiSelect;
	MultiSelectMove;
	None; // possibly handled externally
}

class KeyboardContainer extends Box {
	static public var BUTTON_CHANGED = "BUTTON_CHANGED";
	static public var BUTTON_CLICKED = "BUTTON_CLICKED";
	static public var BUTTON_DOWN = "BUTTON_MOUSE_DOWN";

	private var scrollView:ScrollView = new ScrollView();
	private var canvas:Absolute = new Absolute();
	private var selectedButtons:Array<KeyButton> = [];
	private var clickingOnButton:Bool = false;
	private var selectionStart:Null<haxe.ui.geom.Point> = null;

	public var buttons(default, null):List<KeyButton> = new List<KeyButton>();

	public var activeButton(get, set):Null<KeyButton>;
	public var scale(default, set):Int = 32;
	public var formatButton:(KeyButton) -> Void;
	public var selectionMode(default, set):SelectionMode = SingleSet;
	public var rectangleSelection:Bool = false;

	public function new() {
		super();
		scrollView.addComponent(canvas);
		// canvas.backgroundColor = 0x00ff00;
		var dummy = new Component(); // hack due to the way absolute gets resized
		canvas.addComponent(dummy);

		scrollView.backgroundColor = 0xcccccc;
		super.addComponent(scrollView);
		scrollView.percentWidth = 100;
		scrollView.percentHeight = 100;

		// scrollView.layout.autoSize(); //TODO: what happens
		scrollView.scrollMode = ScrollMode.NORMAL;

		formatButton = defaultFormat;
		percentWidth = 100;
		percentHeight = 100;

		this.registerEvent(MouseEvent.MOUSE_DOWN, onMouseDownArea);
		this.registerEvent(MouseEvent.MOUSE_UP, onMouseUpArea);
	}

	public function refreshFormatting() {
		for (button in buttons) {
			button.refresh();
			formatButton(button);
		}
	}

	public function refreshButtonFormatting(button:KeyButton) {
		if (button != null) {
			button.refresh();
			formatButton(button);
		}
	}

	public function clearSelection() {
		unselectButtons();
	}

	public function activeButtons():Array<KeyButton> {
		return selectedButtons;
	}

	public function loadFromList(keys:Array<Key>) {
		var activeId = selectedButtons.map(b -> b.key.id);
		clear();

		clearSelection();
		for (key in keys) {
			var button = addKey(key);
			if (activeId.indexOf(key.id) >= 0) {
				selectButton(button, Add);
			}
		}
		refreshFormatting();
	}

	public function defaultFormat(key:KeyButton) {
		key.text = key.key.name;
	}

	public function screenToField(x:Float, y:Float):Point {
		var result:Point = {x: 0, y: 0};

		result.x = (x - canvas.screenLeft) / scale;
		result.y = (y - canvas.screenTop) / scale;
		return result;
	}

	override public function addComponent(child:Component):Component {
		var res:Component = canvas.addComponent(child);
		return res;
	}

	public function updateLayout() {
		canvas.autoSize();
	}

	public function addKey(key:Key):KeyButton {
		var button:KeyButton = new KeyButton(key);
		button.scale = scale;
		button.onClick = onKeyClick;
		button.registerEvent(MouseEvent.MOUSE_DOWN, onMouseDown);
		addComponent(button);
		buttons.add(button);
		return button;
	}

	public function removeKey(key:KeyButton) {
		buttons.remove(key);
		removeComponent(key);
	}

	public function clear() {
		clearSelection();
		for (button in buttons) {
			removeKey(button);
		}
	}

	function set_scale(v:Int):Int {
		scale = v;
		for (button in buttons) {
			button.scale = v;
		}
		return v;
	}

	function get_activeButton():Null<KeyButton> {
		if (selectedButtons.length > 0) {
			return selectedButtons[selectedButtons.length - 1];
		} else {
			return null;
		}
	}

	function set_activeButton(button:Null<KeyButton>):Null<KeyButton> {
		selectButton(button, Set);
		return button;
	}

	private function unselectButtons() {
		for (button in selectedButtons) {
			button.selected = false;
		}
		selectedButtons = [];
	}

	public function selectButton(button:Null<KeyButton>, mode:SelectionCommand = Set) {
		if (mode == Set) {
			unselectButtons();
			if (button != null) {
				selectedButtons.push(button);
				button.selected = true;
			}
			dispatch(new KeyButtonEvent(BUTTON_CHANGED, button));
			return;
		}
		if (button == null) {
			return;
		}

		if (mode == Add) {
			var index = selectedButtons.indexOf(button);
			if (index >= 0) {
				selectedButtons[index] = selectedButtons[selectedButtons.length - 1];
				selectedButtons[selectedButtons.length - 1] = button;
				return;
			}
			selectedButtons.push(button);
			button.selected = true;
			dispatch(new KeyButtonEvent(BUTTON_CHANGED, button));
		} else if (mode == Toggle) {
			if (selectedButtons.remove(button)) {
				button.selected = false;
			} else {
				button.selected = true;
				selectedButtons.push(button);
			}
		} else if (mode == Remove) {
			if (selectedButtons.remove(button)) {
				button.selected = false;
			}
		}
		dispatch(new KeyButtonEvent(BUTTON_CHANGED, activeButton));
	}

	public function getButton(key:Key):Null<KeyButton> {
		for (button in buttons) {
			if (button.key == key) {
				return button;
			}
		}
		return null;
	}

	function set_selectionMode(mode:SelectionMode):SelectionMode {
		this.selectionMode = mode;
		return mode;
	}

	private function onKeyClick(e:MouseEvent) {
		dispatch(new KeyButtonEvent(BUTTON_CLICKED, cast e.target));
		var button:KeyButton = cast e.target;
		switch selectionMode {
			case SingleSet:
				selectButton(button, Set);
			case MultiSelect:
				selectButton(button, e.shiftKey ? Toggle : Set);
			case MultiSelectMove:
				if (e.shiftKey) {
					selectButton(button, Toggle);
				} else if (selectedButtons.indexOf(button) >= 0) {
					selectButton(button, Add);
				} else {
					selectButton(button, Set);
				}
			case None:
		}
	}

	private function onMouseDown(e:MouseEvent) {
		clickingOnButton = true;
		var target:KeyButton = cast e.target;
		var result = new KeyButtonEvent(BUTTON_DOWN, target);
		result.mouseEvent = e;
		dispatch(result);
	}

	private function onMouseDownArea(e:MouseEvent) {
		trace('mouse down area ${e.target}');
		if (rectangleSelection && !clickingOnButton) {
			selectionStart = new haxe.ui.geom.Point(e.localX, e.localY);
		}
	}

	private function onMouseUpArea(e:MouseEvent) {
		clickingOnButton = false;
		if (selectionStart != null) {
			var top = Math.min(selectionStart.y, e.localY);
			var bottom = Math.max(selectionStart.y, e.localY);
			var left = Math.min(selectionStart.x, e.localX);
			var right = Math.max(selectionStart.x, e.localX);
			if (!e.shiftKey) {
				unselectButtons();
			}
			for (button in buttons) {
				if (button.top >= top
					&& button.left >= left
					&& button.top + button.height <= bottom
					&& button.width + button.left <= right
					&& !button.selected) {
					selectedButtons.push(button);
					button.selected = true;
				}
			}
			dispatch(new KeyButtonEvent(BUTTON_CHANGED, activeButton));
		}
		selectionStart = null;
	}
}

class KeyButtonEvent extends UIEvent {
	public function new(type:String, target:KeyButton) {
		super(type);
		data = target;
	}

	public var button(get, set):KeyButton;
	public var mouseEvent:Null<MouseEvent> = null;

	function get_button():KeyButton {
		return data;
	}

	function set_button(btn:KeyButton):KeyButton {
		data = btn;
		return btn;
	}

	override public function clone():UIEvent {
		var c = new KeyButtonEvent(type, button);
		c.target = target;
		c.mouseEvent = mouseEvent;
		postClone(c);
		return c;
	}
}
