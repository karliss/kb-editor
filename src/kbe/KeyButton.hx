package kbe;

import kbe.components.KeyboardContainer;
import kbe.components.OneWayButton;

class KeyButton extends OneWayButton {
	public var key(default, null):Key;

	public function new(key:Key = null) {
		super();
		if (key == null) {
			throw "Bad call";
		}
		this.key = key;
	}
}
