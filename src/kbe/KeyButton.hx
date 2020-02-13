package kbe;

import kbe.components.KeyboardContainer;
import kbe.components.OneWayButton;

class KeyButton extends OneWayButton {
	public var key(default, null):Key;
	public var scale:Float = 32;

	public function new(key:Key = null) {
		super();
		if (key == null) {
			throw "Bad call";
		}
		this.key = key;
		refresh();
	}

	public function refresh() {
		top = KeyboardContainer.TOP_OFFSET + key.y * scale;
		left = KeyboardContainer.LEFT_OFFSET + key.x * scale;
		width = key.width * scale;
		height = key.height * scale;
	}
}
