extends Program
class_name FileExplorerProgram

var browser: OSFileBrowser
var start_directory : String = ""
var _prog_title: String = "Pixel Browser"

func _program_start(args: Array = []) -> void:
	print("%s started" % _prog_title)
	
	if args.size() > 0 and not (args[0] as String).is_empty():
		start_directory = args[0]
		if DirAccess.dir_exists_absolute(start_directory):
			browser.open_directory(start_directory)

func _program_end() -> void:
	print("%s ended" % _prog_title)
func _program_ready() -> void:
	title = _prog_title
	
	browser = OSFileBrowser.new()
	browser.file_mode = OSFileBrowser.FileMode.OPEN_FILE
	browser.allow_file_operations = true
	browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(browser)
	
	browser.file_activated.connect(_on_file_activated)
	browser.selection_changed.connect(_on_selection_changed)

## Attempt to open file with the correct program
func _on_file_activated(path: String) -> void:
	var ext = path.get_extension().to_lower()
	
	match ext:
		"txt", "md", "gd", "json", "xml", "log":
			Global.main_ui.run_program_by_id("text_editor", [path])
		"html":
			Global.main_ui.run_program_by_id("browser", [path])
		_:
			# Ask what to open with
			var confirm = OSConfirmationDialog.create(
				"Open with Text Editor?",
				"Open",
				"Cancel"
			)
			window_parent.add_child(confirm)
			confirm.confirmed.connect(func():
				Global.main_ui.run_program_by_id("text_editor", [path])
			)

## Update window title
func _on_selection_changed(paths: PackedStringArray) -> void:
	if paths.size() == 1:
		title = "%s - " % _prog_title + paths[0].get_file()
	elif paths.size() > 1:
		title = "%s - %d items selected" % [_prog_title, paths.size()]
	else:
		title = "%s - " % _prog_title + browser.get_current_dir().get_file()
