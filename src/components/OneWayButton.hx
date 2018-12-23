package components;

import haxe.ui.components.Button;
import haxe.ui.core.MouseEvent;

class OneWayButton extends Button {
	function new() {
		super();
		toggle = true;
	}

	override function _onMouseClick(event:MouseEvent) {
		if (!selected) {
			super._onMouseClick(event);
		}
		// do nothing if already selected
	}
}
