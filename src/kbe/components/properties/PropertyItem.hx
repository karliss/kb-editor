package kbe.components.properties;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;

class PropertyItem extends HBox {
	var label:Label;
	var editor:Null<haxe.ui.core.Component> = null;

	public var propertyId:String = "";

	public function new() {
		super();
		var label = new Label();
		this.label = label;
		addComponent(label);
		label.percentWidth = 50;
		this.percentWidth = 100;
	}

	override function get_text():String {
		return label.text;
	}

	override function addComponent(child:Component):Component {
		if (label == null) {
			return super.addComponent(child);
		}
		super.addComponent(child);
		editor = child;
		child.percentWidth = 50;
		child.registerEvent(UIEvent.CHANGE, function(e:UIEvent) {
			dispatch(new UIEvent(UIEvent.CHANGE));
		});
		return child;
	}

	override function set_value(v:Dynamic):Dynamic {
		if (editor == null) {
			// not initialized
			return [];
		}
		return editor.value = v;
	}

	override function get_value():Dynamic {
		if (editor == null) {
			// not initialized
			return [];
		}
		return editor.value;
	}

	override function set_text(text:String):String {
		return label.text = text;
	}
}
