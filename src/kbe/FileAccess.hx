package kbe;

import haxe.io.Bytes;
#if js
import js.Browser;
import js.html.Blob;
import js.html.FileSaver;
import js.lib.Uint8Array;
#end

class FileAccess {
	public static function saveFile(data:Bytes, preferredName:String) {
		#if js
		var intArray = new Array<Int>();
		for (i in 0...data.length) {
			intArray.push(data.get(i));
		}
		FileSaver.saveAs(new Blob([new Uint8Array(intArray)]), preferredName, true);
		#else
		throw "File access not implemented";
		#end
	}
}
