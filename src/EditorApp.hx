package ;

import haxe.ui.HaxeUIApp;
import haxe.ui.core.Component;
import haxe.ui.macros.ComponentMacros;
import components.KeyboardContainer;

import haxe.ui.components.Button;

class EditorApp extends HaxeUIApp {
    public function new() {
        super();
        ready(onReady);
    }

    private function onReady() {
        var com:KeyboardContainer = new KeyboardContainer();

        var editor:Component = new Editor();
        addComponent(editor);
        editor.percentWidth = 100;
        editor.percentHeight = 100;
        
        start();
    }

    public static function main() {
        new EditorApp();
    }
}
