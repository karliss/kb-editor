![example workflow](https://github.com/karliss/kb-editor/actions/workflows/testing.yaml/badge.svg)

# kb-editor
Tool for editing layouts of custom keyboards. Try it [here](https://karliss.github.io/kb-editor/preview). 

It is intended for keeping track of mapping between physical layout, logical layout, wiring matrix and scanning matrix and generating configuration files from this information.

[image physical layout edit](docs/images/readmed_p.png)
[image wiring edit](docs/images/readmed_w.png)

## Project status

Early development - not exactly end user robust, but has enough functionality to be useful for my personal use

* Physical layout definition - mostly working
* Logical layout mapping - done
* Wiring and scan matrix - done
* Importers - mostly working
* Exporters - helps dealing with most tedious parts related to keys, rest of the config my need manual editing
   - QMK info.json matrix pins, layout (positions and matrix)
   - KLE - basic position, size, label (no advanced styling features)
   - QMK layout macro -> pretty prints taking into account key width. Somewhat redundant due to QMK data driven configuration.
   - QMK keymap.json template -> some fancy formating, for manual editing. No wey to define the content of keymap. 
   - VIA json -> VIA specific values need to be filled in manually after exporting
* Key mapping configuration - missing, low priority due to plenty of existing tools doing that

## Comparison with other tools

* keyboard-layout-editor.com - Focuses on keyboard visual properties. Usefull when desigining look or planning what keycaps to order. Such functionality is currently out of scope for kb-editor.  keyboard-layout-editor has almost no function related to configuring keyboard firwmare.

* QMK Configurator - Key mapping configuration tool for end users of existing keyboards. Can build the firmware image. Doesn't help preparing initial configuration when creating a new keyboard. Firmware compilation is out of scope for kb-editor.

* [Keyboard Firmware Builder](https://kbfirmware.com/) - Similar set of functionality. For limited set of platforms allows very detailed configuration including wiring matrix, pins for key and led connections, basic backlight, macro definition, custom C code snipets. Supports firmware compilation. Import and export formats are very limited. Doesn't support layout creation (needs to be done in KBLE). Almost usless if desired configurtion falls outside set of supported platforms.