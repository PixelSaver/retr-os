extends OSDialog
class_name OSFileDialog

signal file_selected(path: String)
signal files_selected(paths: PackedStringArray)
signal dir_selected(dir: String)

var browser: OSFileBrowser
var ok_button: Button
var cancel_button: Button

const OS_FILE_DIALOG = preload("uid://q0n1glrx3cko")

static func create(mode: OSFileBrowser.FileMode = OSFileBrowser.FileMode.OPEN_FILE) -> OSFileDialog:
	var dialog = OS_FILE_DIALOG.instantiate()
	dialog.browser = OSFileBrowser.new()
	dialog.browser.file_mode = mode
	dialog.is_modal = true
	return dialog

func _ready() -> void:
	await get_tree().process_frame
	super._ready()
	_build_dialog()

func _build_dialog() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	program_container.add_child(vbox)
	
	# Add browser
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(browser)
	
	# Connect browser signals
	browser.file_selected.connect(_on_browser_file_selected)
	browser.files_selected.connect(_on_browser_files_selected)
	browser.file_activated.connect(_on_file_activated)
	
	# Buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_END
	button_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(button_hbox)
	
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 30)
	button_hbox.add_child(cancel_button)
	cancel_button.pressed.connect(func(): close_dialog("cancel"))
	
	ok_button = Button.new()
	ok_button.custom_minimum_size = Vector2(80, 30)
	button_hbox.add_child(ok_button)
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Set button text based on mode
	match browser.file_mode:
		OSFileBrowser.FileMode.OPEN_FILE, OSFileBrowser.FileMode.OPEN_FILES:
			ok_button.text = "Open"
		OSFileBrowser.FileMode.OPEN_DIR:
			ok_button.text = "Select"
		OSFileBrowser.FileMode.SAVE_FILE:
			ok_button.text = "Save"
	
	# Set window properties
	custom_init(Vector2(30, 30))

# Public API

func add_filter(description: String, extensions: PackedStringArray) -> void:
	browser.add_filter(description, extensions)

func set_current_dir(path: String) -> void:
	browser.open_directory(path)

func set_current_file(file_name: String) -> void:
	browser.set_current_file(file_name)

# Signal handlers

func _on_browser_file_selected(path: String) -> void:
	file_selected.emit(path)

func _on_browser_files_selected(paths: PackedStringArray) -> void:
	files_selected.emit(paths)

func _on_file_activated(path: String) -> void:
	# Double-click should close dialog and select
	file_selected.emit(path)
	close_dialog("ok")

func _on_ok_pressed() -> void:
	match browser.file_mode:
		OSFileBrowser.FileMode.OPEN_FILE:
			var file = browser.get_selected_file()
			if not file.is_empty() and FileAccess.file_exists(file):
				file_selected.emit(file)
				close_dialog("ok")
		
		OSFileBrowser.FileMode.OPEN_FILES:
			var files = browser.get_selected_files()
			if files.size() > 0:
				files_selected.emit(files)
				close_dialog("ok")
		
		OSFileBrowser.FileMode.OPEN_DIR:
			dir_selected.emit(browser.get_current_dir())
			close_dialog("ok")
		
		OSFileBrowser.FileMode.SAVE_FILE:
			var filename = browser.get_selected_file()
			if filename.is_empty() and browser.filename_edit:
				filename = browser.current_dir.path_join(browser.filename_edit.text)
			
			if not filename.is_empty():
				if FileAccess.file_exists(filename):
					var confirm = OSConfirmationDialog.create("File exists. Overwrite?", "Overwrite", "Cancel")
					get_parent().add_child(confirm)
					confirm.confirmed.connect(func():
						file_selected.emit(filename)
						close_dialog("ok")
					)
				else:
					file_selected.emit(filename)
					close_dialog("ok")
