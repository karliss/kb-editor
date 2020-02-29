package kbe;

import haxe.ui.HaxeUIApp;
import haxe.ui.core.Component;

class EditorApp extends HaxeUIApp {
	public function new() {
		super();
		ready(onReady);
	}

	private function onReady() {
		var editor:Component = new EditorGui();
		editor.percentWidth = 100;
		editor.percentHeight = 100;
		addComponent(editor);
		start();
	}

	public static function main() {
		new EditorApp();
	}
}
