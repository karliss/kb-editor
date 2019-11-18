package kbe.components.properties;

import haxe.ui.components.Button;
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

	var contentElements = new Array<Component>();

	public function new() {
		super();
		addClass("accordion");
	}

	override function addComponent(child:Component):Component {
		child.addClass("accordion-content");
		var result = super.addComponent(child);
		contentElements.push(child);
		var button:Button = cast result;
		// button.selected = true; doesn't work
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
			var findByid = function(object:Component, id:String):PropertyItem {
				var tc = object.findComponent(id, PropertyItem, true);
				if (tc == null) {
					tc = object.findComponent("p_" + id, PropertyItem, true);
				}
				return tc;
			};
			var c = findByid(this, f);
			if (c == null) {
				for (group in contentElements) {
					c = findByid(group, f);
					if (c != null) {
						break;
					}
				}
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
