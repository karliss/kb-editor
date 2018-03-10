package components.properties;

import haxe.ui.containers.ListView;
import haxe.ui.core.Component;

class PropertyEditor extends ListView {
    function new() {
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
        var firstIndex = contents.getComponentIndex(title);
        var n = contents.childComponents.length;
        for (i in (firstIndex+1)...n) {
            var component = contents.getComponentAt(i);
            if (Std.is(component, PropertyTitle)) {
                break;
            }
            component.hidden = !expanded;
        }
    }
}
