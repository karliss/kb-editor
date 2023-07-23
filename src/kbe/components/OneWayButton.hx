package kbe.components;

import haxe.ui.components.Button;
import haxe.ui.events.MouseEvent;

class OneWayButton extends Button {
	public function new() {
		super();
		addClass("button");
		this.native = true;
		this.toggle = true;
		this.registerEvent(MouseEvent.CLICK, onMouseClick);
		addClass("button");
	}

	function onMouseClick(event:MouseEvent) {
		this.selected = true;
	}
}
