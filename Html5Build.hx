class Html5Build {
	static public function main():Void {
		var input = "FileSaver.js/dist/FileSaver.js";
		trace("Copying $input");
		sys.io.File.copy(input, "build/html5/FileSaver.js");
	}
}
