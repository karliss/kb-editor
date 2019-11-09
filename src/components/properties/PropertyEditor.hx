package components.properties;

import haxe.ui.containers.ListView;
import haxe.ui.containers.Accordion;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.util.Variant;
import haxe.ui.events.UIEvent;

class PropertyEditor extends Accordion {
	public var source(default, set):Dynamic; // TODO:better use haxeui datasource
	public var autoSync:Bool = true; // TODO: haxeui sync?

	var mapping:Map<String, PropertyItem> = new Map<String, PropertyItem>();

	public function new() {
		super();
		addClass("accordion");
	}

	override function addComponent(child:Component):Component {
		child.addClass("accordion-content");
		var result = super.addComponent(child);
		return result;
	}

	function set_source(newValue):Dynamic {
		if (source == null) {
			doBinding(newValue);
		}
		source = null;
		toUi(newValue);
		source = newValue;
		return source;
	}

	function doBinding(source:Dynamic) {
		for (f in Reflect.fields(source)) {
			var c = findComponent(f, PropertyItem, true);
			if (c == null) {
				c = findComponent("p_" + f, PropertyItem, true);
			}
			if (c != null) {
				c.propertyId = f;
				mapping[f] = c;
				c.onChange = onComponentChange;
			}
		}
	}

	function onComponentChange(e:haxe.ui.events.UIEvent) {
		if (!autoSync || source == null) {
			return;
		}
		var c = Std.downcast(e.target, PropertyItem);
		if (c == null) {
			return;
		}
		var field = c.propertyId;
		Reflect.setField(source, field, c.value);
		dispatch(new UIEvent(UIEvent.CHANGE));
	}

	function toUi(source:Dynamic) {
		for (f in mapping.keys()) {
			var fName:String = f;
			var c = mapping[fName];
			c.value = Reflect.field(source, fName);
		}
	}
}
