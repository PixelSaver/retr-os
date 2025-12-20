extends Program
class_name FileExplorerProgram

var start_directory : String = ""

func _program_start(args:Array=[]) -> void:
	if args.size() > 0 and not (args[0] as String).is_empty():
		start_directory = args[0]
		

func _program_end() -> void:
	pass
	
func _program_ready() -> void:
	hide()
	var dialog = OSFileDialog.create(OSFileBrowser.FileMode.OPEN_FILE)
	dialog.add_filter("Text Files", PackedStringArray(["txt"]))
	dialog.add_filter("GDScript Files", PackedStringArray(["gd"]))
	dialog.add_filter("All Files", PackedStringArray(["*"]))
	
	#add_child(dialog)
	
	Global.main_ui.window_container.add_child(dialog)
	
	dialog.file_selected.connect(_on_file_opened)
	close_program_window()

func _on_file_opened(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		Global.main_ui.run_program_by_id("text_editor", [path])
