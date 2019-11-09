package components.properties;

import haxe.ui.containers.ListView;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.util.Variant;
import haxe.ui.events.UIEvent;

class PropertyEditor extends VBox {
	public var source(default, set):Dynamic; // TODO:better use haxeui datasource
	public var autoSync:Bool = true; // TODO: haxeui sync?

	var mapping:Map<String, PropertyItem> = new Map<String, PropertyItem>();

	public function new() {
		super();
	}

	override function addComponent(child:Component):Component {
		var result = super.addComponent(child);
		if (Std.is(child, PropertyTitle)) {
			var title:PropertyTitle = cast child;
			title.onExpand = function(expanded) {
				groupExpand(title, expanded);
			}
		}
		result.addClass(this._children.length % 2 == 0 ? "even" : "odd");
		return result;
	}

	function groupExpand(title:PropertyTitle, expanded:Bool) {
		var firstIndex = getComponentIndex(title); // contents.getComponentIndex(title);
		var n = childComponents.length; // contents.childComponents.length;
		for (i in (firstIndex + 1)...n) {
			var component = getComponentAt(i); // contents.getComponentAt(i);
			if (Std.is(component, PropertyTitle)) {
				break;
			}
			component.hidden = !expanded;
		}
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
