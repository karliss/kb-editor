package kbe;

import haxe.io.Bytes;
#if js
import js.html.FileList;
import js.html.InputElement;
import js.html.HTMLDocument;
import js.html.File;
import js.html.FileReader;
import js.lib.Uint8Array;
#end

typedef FileCallback = Array<Bytes>->Array<String>->Void;

#if js
// TODO:[#1] make js part conditional
class FileOpener {
	private static var uploader:InputElement;
	private static var ID = "HiddenFileOpener";

	var data = new Array<Bytes>();
	var names = new Array<String>();
	var filesToProcess = new Array<File>();
	var reader = new FileReader();
	var callback:FileCallback;

	public static function tryToOpenFile(callback:FileCallback):Void {
		var uploader = getUploader();
		var handler = new FileOpener(callback);
		uploader.onchange = function() {
			handler.onFiles(uploader.files);
		}
		uploader.click();
	}

	static function getUploader():InputElement {
		if (FileOpener.uploader == null) {
			var document:HTMLDocument = js.Browser.document;
			uploader = document.createInputElement();
			uploader.hidden = true;
			uploader.id = ID;
			uploader.type = "file";
			document.body.appendChild(uploader);
		}
		return uploader;
	}

	function new(callback:FileCallback) {
		this.callback = callback;
	}

	function onFiles(fileList:FileList) {
		for (file in fileList) {
			filesToProcess.push(file);
		}
		reader.onload = onLoad;
		readNextFile();
	}

	function readNextFile() {
		if (filesToProcess.length == 0) {
			return;
		}
		var next = filesToProcess.pop();
		names.push(next.name);
		reader.readAsArrayBuffer(next);
	}

	function onLoad() {
		var jsBytes = new Uint8Array(reader.result);
		var haxeBytes = Bytes.alloc(jsBytes.length);
		for (i in 0...jsBytes.length) {
			haxeBytes.set(i, jsBytes[i]);
		}

		data.push(haxeBytes);

		if (filesToProcess.length > 0) {
			readNextFile();
		} else {
			callback(data, names);
		}
	}
}
#end
