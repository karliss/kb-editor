package kbe.components;

import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.constants.ScrollMode;

typedef Point = {x:Float, y:Float}

class KeyboardContainer extends Box {
	static public var BUTTON_CHANGED = "BUTTON_CHANGED";
	static public var BUTTON_DOWN = "BUTTON_MOUSE_DOWN";

	private var scrollView:ScrollView = new ScrollView();
	private var canvas:Absolute = new Absolute();
	private var buttons:List<KeyButton> = new List<KeyButton>();

	public var activeButton(default, set):Null<KeyButton> = null;
	public var scale(default, set):Int = 32;
	public var formatButton:(KeyButton) -> Void;

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

	public function loadFromList(keys:Array<Key>) {
		var activeId = -1;
		if (activeButton != null) {
			activeId = activeButton.key.id;
		}
		clear();

		for (key in keys) {
			var button = addKey(key);
			if (key.id == activeId) {
				activeButton = button;
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
		activeButton = null;
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

	function set_activeButton(button:KeyButton):KeyButton {
		if (activeButton != null) {
			activeButton.selected = false;
		}
		activeButton = button;
		if (activeButton != null) {
			activeButton.selected = true;
		}
		dispatch(new KeyButtonEvent(BUTTON_CHANGED, activeButton));
		return button;
	}

	public function getButton(key:Key):Null<KeyButton> {
		for (button in buttons) {
			if (button.key == key) {
				return button;
			}
		}
		return null;
	}

	private function onKeyClick(e:MouseEvent) {
		activeButton = cast e.target;
	}

	private function onMouseDown(e:MouseEvent) {
		var target:KeyButton = cast e.target;
		var result = new KeyButtonEvent(BUTTON_DOWN, target);
		result.mouseEvent = e;
		dispatch(result);
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