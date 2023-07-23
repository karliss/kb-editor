package kbe.components;

import haxe.ui.events.KeyboardEvent;
import haxe.ui.util.Color;
import haxe.ui.components.Button;
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
	SingleToggle;
	MultiSelect;
	MultiSelectMove;
	None; // possibly handled externally
}

class KeyboardContainer extends Box {
	static public var BUTTON_CHANGED = "BUTTON_CHANGED";
	static public var BUTTON_CLICKED = "BUTTON_CLICKED";
	static public var BUTTON_DOWN = "BUTTON_MOUSE_DOWN";
	public static var TOP_OFFSET = 32;
	public static var LEFT_OFFSET = 32;

	private var scrollView:ScrollView = new ScrollView();
	private var canvas:Absolute = new Absolute();
	private var selectedButtons:Array<KeyButton> = [];
	private var clickingOnButton:Bool = false;
	private var selectionStart:Null<haxe.ui.geom.Point> = null;
	private var selectionRect:Null<Component> = null;

	public var buttons(default, null):List<KeyButton> = new List<KeyButton>();

	public var activeButton(get, set):Null<KeyButton>;
	public var scale(default, set):Float = 32.0;
	public var formatButton:(KeyButton) -> Void;
	public var selectionMode(default, set):SelectionMode = SingleSet;
	public var rectangleSelection:Bool = false;
	public var flipHorizontally(default, set) = false;
	public var flipVertically(default, set) = false;

	public function new() {
		formatButton = defaultFormat;
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

		percentWidth = 100;
		percentHeight = 100;

		canvas.registerEvent(MouseEvent.MOUSE_DOWN, onMouseDownArea);
		canvas.registerEvent(MouseEvent.MOUSE_UP, onMouseUpArea);
		canvas.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMoveCanvas);
		this.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMoveSelf);

		#if js
		this.element.tabIndex = 1;
		#end
	}

	public function refreshFormatting() {
		for (button in buttons) {
			refreshButtonFormatting(button);
		}
	}

	public function refreshButtonFormatting(button:KeyButton) {
		if (button != null) {
			var key = button.key;
			var pos = fieldToScreen(key);
			button.top = pos.y;
			button.left = pos.x;
			button.width = key.width * scale;
			button.height = key.height * scale;
			formatButton(button);
		}
	}

	public function clearSelection() {
		unselectButtons();
	}

	public function activeButtons():Array<KeyButton> {
		return selectedButtons;
	}

	public function selectedKeys():Array<Key> {
		return selectedButtons.map(button -> button.key);
	}

	public function loadFromList(keys:Array<Key>) {
		var activeId = selectedButtons.map(b -> b.key.id);
		clear();

		clearSelection();
		for (key in keys) {
			var button = addKey(key);
		}
		// Preserve order
		for (id in activeId) {
			for (button in buttons) {
				if (button.key.id == id) {
					selectButton(button, SelectionCommand.Add);
				}
			}
		}
		refreshFormatting();
	}

	public function defaultFormat(key:KeyButton) {
		key.text = key.key.name;
	}

	public function fieldToScreen(key:Key):Point {
		var y:Float = 0.0;
		var x:Float = 0.0;
		var areaWidth = width;
		if (areaWidth == null) {
			areaWidth = 300;
		}
		var areaHeight = height;
		if (areaHeight == null) {
			areaHeight = 300;
		}

		if (flipHorizontally) {
			x = 0.8 * areaWidth + KeyboardContainer.LEFT_OFFSET - (key.x + key.width) * scale;
		} else {
			x = KeyboardContainer.LEFT_OFFSET + key.x * scale;
		}
		if (flipVertically) {
			y = 0.8 * areaHeight + KeyboardContainer.TOP_OFFSET - (key.y + key.height) * scale;
		} else {
			y = KeyboardContainer.TOP_OFFSET + key.y * scale;
		}
		return {x: x, y: y};
	}

	public function screenToField(x:Float, y:Float):Point {
		var result:Point = {x: 0, y: 0};

		result.x = (x - canvas.screenLeft - LEFT_OFFSET) / scale;
		result.y = (y - canvas.screenTop - TOP_OFFSET) / scale;
		return result;
	}

	override public function addComponent(child:Component):Component {
		var res:Component = canvas.addComponent(child);
		return res;
	}

	public function updateLayout() {
		// canvas.autoHeight = canvas.autoWidth = true;
		canvas.height = null;
		canvas.width = null;
		canvas.autoSize();

		var cw = canvas.width;
		var ch = canvas.height;
		var thisW = this.width;
		var thisH = this.height;
		if (thisH != null && thisW != null) {
			if (cw != null && this.width != null) {
				var w = Math.max(cw, thisW - 16);
				if (w > 0) {
					canvas.width = w;
				}
			}
			if (ch != null) {
				var h = Math.max(ch, thisH - 16);
				if (h > 0) {
					canvas.height = h;
				}
			}
		}
	}

	@:bind(this, UIEvent.RESIZE)
	function onResize(_) {
		updateLayout();
	}

	public function addKey(key:Key):KeyButton {
		var button:KeyButton = new KeyButton(key);
		button.onClick = onKeyClick;
		button.registerEvent(MouseEvent.MOUSE_DOWN, onMouseDown);
		addComponent(button);
		buttons.add(button);
		refreshButtonFormatting(button);
		return button;
	}

	public function removeKey(key:KeyButton) {
		buttons.remove(key);
		canvas.removeComponent(key, false, false);
	}

	public function clear() {
		clearSelection();
		for (button in buttons) {
			removeKey(button);
		}
	}

	function set_scale(v:Float):Float {
		scale = v;
		refreshFormatting();
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
		selectButtonInternal(button, mode, true);
	}

	public function selectButtons(selection:Array<KeyButton>) {
		unselectButtons();
		var singleButton:Null<KeyButton> = null;
		for (button in selection) {
			button.selected = true;
			singleButton = button;
		}
		selectedButtons = selection.copy();
		dispatch(new KeyButtonEvent(BUTTON_CHANGED, singleButton, true));
	}

	public function selectButtonInternal(button:Null<KeyButton>, mode:SelectionCommand = Set, software:Bool = false) {
		if (mode == Set) {
			unselectButtons();
			if (button != null) {
				selectedButtons.push(button);
				button.selected = true;
			}
			dispatch(new KeyButtonEvent(BUTTON_CHANGED, button, software));
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
			dispatch(new KeyButtonEvent(BUTTON_CHANGED, button, software));
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
		dispatch(new KeyButtonEvent(BUTTON_CHANGED, activeButton, software));
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
				selectButtonInternal(button, Set);
			case SingleToggle:
				if (activeButton == button) {
					selectButtonInternal(button, Toggle);
				} else {
					selectButtonInternal(button, Set);
				}
			case MultiSelect:
				selectButtonInternal(button, e.shiftKey ? Toggle : Set);
			case MultiSelectMove:
				if (e.shiftKey) {
					selectButtonInternal(button, Toggle);
				} else if (selectedButtons.indexOf(button) >= 0) {
					selectButtonInternal(button, Add);
				} else {
					selectButtonInternal(button, Set);
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
		if (rectangleSelection && !clickingOnButton) {
			selectionStart = new haxe.ui.geom.Point(e.localX, e.localY);
			if (selectionRect != null) {
				canvas.removeComponent(selectionRect);
			}
			selectionRect = new Box();
			canvas.addComponent(selectionRect);
			selectionRect.top = selectionStart.y;
			selectionRect.left = selectionStart.x;
			selectionRect.borderColor = 0x00ff00;
			selectionRect.borderSize = 5;
			selectionRect.borderRadius = 5;
			selectionRect.backgroundColor = 0xff0000;
			selectionRect.opacity = 0.5;
		}
	}

	private function onMouseMoveCanvas(e:MouseEvent) {
		if (selectionRect != null && selectionStart != null) {
			var localX = e.localX, localY = e.localY;
			if (localY == null || localX == null) {
				return;
			}
			selectionRect.left = Math.min(localX, selectionStart.x);
			selectionRect.top = Math.min(localY, selectionStart.y);
			selectionRect.width = Math.abs(localX - selectionStart.x);
			selectionRect.height = Math.abs(localY - selectionStart.y);
			var width = canvas.width;
			var height = canvas.height;
			if (width != null && height != null) {
				canvas.width = Math.max(width, localX + 32);
				canvas.height = Math.max(height, localY + 32);
			}
		}
	}

	private function onMouseMoveSelf(e:MouseEvent) {
		if (selectionRect != null) {
			var localX = e.localX, localY = e.localY;
			if (localY == null || localX == null) {
				return;
			}
			var canvasWidth = canvas.width;
			var canvasHeight = canvas.height;
			if (canvasWidth == null || canvasHeight == null) {
				canvas.width = localX + 32;
				canvas.height = localY + 32;
			} else {
				canvas.width = Math.max(canvasWidth, localX + 32);
				canvas.height = Math.max(canvasHeight, localY + 32);
			}
		}
	}

	private function onMouseUpArea(e:MouseEvent) {
		clickingOnButton = false;
		if (selectionStart != null && selectionRect != null) {
			canvas.removeComponent(selectionRect);
			selectionRect = null;
			var localX = e.localX, localY = e.localY;
			if (localY == null || localX == null) {
				return;
			}
			var top = Math.min(selectionStart.y, localY);
			var bottom = Math.max(selectionStart.y, localY);
			var left = Math.min(selectionStart.x, localX);
			var right = Math.max(selectionStart.x, localX);
			if (!e.shiftKey) {
				unselectButtons();
			}

			for (button in buttons) {
				var buttonTop = button.top;
				var buttonLeft = button.left;
				var buttonWidth = button.width;
				var buttonHeight = button.height;
				if (buttonTop == null || buttonLeft == null || buttonWidth == null || buttonHeight == null) {
					continue;
				}
				if (buttonTop >= top && buttonLeft >= left && buttonTop + buttonHeight <= bottom && buttonWidth + buttonLeft <= right && !button.selected) {
					selectedButtons.push(button);
					button.selected = true;
				}
			}
			dispatch(new KeyButtonEvent(BUTTON_CHANGED, activeButton));
		}
		selectionStart = null;
	}

	function set_flipHorizontally(v:Bool):Bool {
		this.flipHorizontally = v;
		refreshFormatting();
		return v;
	}

	function set_flipVertically(v:Bool):Bool {
		this.flipVertically = v;
		refreshFormatting();
		return v;
	}
}

class KeyButtonEvent extends UIEvent {
	public function new(type:String, target:Null<KeyButton>, software:Bool = false) {
		super(type);
		data = target;
		this.software = software;
	}

	public var button(get, set):Null<KeyButton>;
	public var mouseEvent:Null<MouseEvent> = null;
	public var software:Bool = false;

	function get_button():Null<KeyButton> {
		return data;
	}

	function set_button(btn:Null<KeyButton>):Null<KeyButton> {
		data = btn;
		return btn;
	}

	override public function clone():UIEvent {
		var c = new KeyButtonEvent(type, button);
		c.target = target;
		c.mouseEvent = mouseEvent;
		c.software = software;
		postClone(c);
		return c;
	}
}
