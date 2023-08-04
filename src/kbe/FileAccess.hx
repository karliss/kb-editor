package kbe;

import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.io.Bytes;

class FileAccess {
	public static function saveFile(data:Bytes, preferredName:String) {
		var dialog = new SaveFileDialog();
		var extension = haxe.io.Path.extension(preferredName);

		dialog.options = {
			title: "Save file",
			writeAsBinary: true,
			extensions: [{label: preferredName, extension: extension}]
		};
		dialog.onDialogClosed = function(event) {
			if (event.button == DialogButton.OK) {
				Dialogs.messageBox("File saved!", "Save Result", MessageBoxType.TYPE_INFO);
			}
		}
		dialog.fileInfo = {
			name: preferredName,
			bytes: data,
		}
		dialog.show();
	}
}
