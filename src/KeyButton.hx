package;


class KeyButton extends haxe.ui.components.Button {
    public var key(default, null):Key;
    public var scale:Float = 32;

    public function new(key:Key=null) {
        super();
        this.key = key;
        refresh();
    }

    public function refresh() {
        top = key.y * scale;
        left = key.x * scale;
        text = key.name;
        width = key.width * scale;
        height = key.height * scale;
    }
}
