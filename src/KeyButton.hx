package;


class KeyButton extends haxe.ui.components.Button {
    public var key(default, null):Key;

    public function new(key:Key=null) {
        super();
        this.key = key;
        refresh();
    }

    public function refresh() {
        top = key.y;
        left = key.x;
        text = key.name;
        width = key.width * 32;
        height = key.height * 32;
    }
}
