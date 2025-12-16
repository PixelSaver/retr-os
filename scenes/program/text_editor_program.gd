extends Program
class_name TextEditorProgram

@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var menu_bar: HBoxContainer = $VBoxContainer/MenuBar
@onready var file_menu: MenuButton = $VBoxContainer/MenuBar/FileMenu
@onready var edit_menu: MenuButton = $VBoxContainer/MenuBar/EditMenu
@onready var status_bar: HBoxContainer = $VBoxContainer/StatusBar
@onready var file_name_label: RichTextLabel = $VBoxContainer/StatusBar/FileNameLabel
@onready var modified_indicator: RichTextLabel = $VBoxContainer/StatusBar/ModifiedIndicator
@onready var line_col_label: RichTextLabel = $VBoxContainer/StatusBar/LineColLabel

var current_file_path: String = ""
var is_modified: bool = false

enum FileMenuId { NEW, OPEN, SAVE, SAVE_AS, CLOSE }
enum EditMenuId { UNDO, REDO, CUT, COPY, PASTE, SELECT_ALL, FIND }

func _program_ready() -> void:
	title = "Text Editor - Untitled"
	_setup_ui()
	_setup_menus()
	_connect_signals()
	_update_status_bar()

func _setup_ui() -> void:
	text_edit.syntax_highlighter = null
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	text_edit.scroll_smooth = true
	text_edit.minimap_draw = true

func _setup_menus() -> void:
	# File menu
	var file_popup = file_menu.get_popup()
	file_popup.clear()
	file_popup.add_item("New", FileMenuId.NEW)
	file_popup.add_item("Open...", FileMenuId.OPEN)
	file_popup.add_separator()
	file_popup.add_item("Save", FileMenuId.SAVE)
	file_popup.add_item("Save As...", FileMenuId.SAVE_AS)
	file_popup.add_separator()
	file_popup.add_item("Close", FileMenuId.CLOSE)
	file_popup.set_item_shortcut(FileMenuId.NEW, _create_shortcut(KEY_N, KEY_MASK_CTRL))
	file_popup.set_item_shortcut(FileMenuId.OPEN, _create_shortcut(KEY_O, KEY_MASK_CTRL))
	file_popup.set_item_shortcut(FileMenuId.SAVE, _create_shortcut(KEY_S, KEY_MASK_CTRL))
	file_popup.set_item_shortcut(FileMenuId.SAVE_AS, _create_shortcut(KEY_S, KEY_MASK_CTRL | KEY_MASK_SHIFT))
	
	# Edit menu
	var edit_popup = edit_menu.get_popup()
	edit_popup.clear()
	edit_popup.add_item("Undo", EditMenuId.UNDO)
	edit_popup.add_item("Redo", EditMenuId.REDO)
	edit_popup.add_separator()
	edit_popup.add_item("Cut", EditMenuId.CUT)
	edit_popup.add_item("Copy", EditMenuId.COPY)
	edit_popup.add_item("Paste", EditMenuId.PASTE)
	edit_popup.add_separator()
	edit_popup.add_item("Select All", EditMenuId.SELECT_ALL)
	edit_popup.add_item("Find...", EditMenuId.FIND)
	edit_popup.set_item_shortcut(EditMenuId.UNDO, _create_shortcut(KEY_Z, KEY_MASK_CTRL))
	edit_popup.set_item_shortcut(EditMenuId.REDO, _create_shortcut(KEY_Y, KEY_MASK_CTRL))
	edit_popup.set_item_shortcut(EditMenuId.CUT, _create_shortcut(KEY_X, KEY_MASK_CTRL))
	edit_popup.set_item_shortcut(EditMenuId.COPY, _create_shortcut(KEY_C, KEY_MASK_CTRL))
	edit_popup.set_item_shortcut(EditMenuId.PASTE, _create_shortcut(KEY_V, KEY_MASK_CTRL))
	edit_popup.set_item_shortcut(EditMenuId.SELECT_ALL, _create_shortcut(KEY_A, KEY_MASK_CTRL))
	edit_popup.set_item_shortcut(EditMenuId.FIND, _create_shortcut(KEY_F, KEY_MASK_CTRL))

func _create_shortcut(key: Key, modifiers: int = 0) -> Shortcut:
	var shortcut = Shortcut.new()
	var event = InputEventKey.new()
	event.keycode = key
	event.ctrl_pressed = (modifiers & KEY_MASK_CTRL) != 0
	event.shift_pressed = (modifiers & KEY_MASK_SHIFT) != 0
	event.alt_pressed = (modifiers & KEY_MASK_ALT) != 0
	shortcut.events = [event]
	return shortcut

func _connect_signals() -> void:
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.caret_changed.connect(_on_caret_changed)
	file_menu.get_popup().id_pressed.connect(_on_file_menu_pressed)
	edit_menu.get_popup().id_pressed.connect(_on_edit_menu_pressed)

func _program_start() -> void:
	print("Text Editor started")
	text_edit.grab_focus()
	_new_file()

func _program_end() -> void:
	print("Text Editor ended")

func can_close() -> bool:
	if not is_modified:
		return true
	
	_show_unsaved_dialog()
	return false

## File Operations

func _new_file() -> void:
	if is_modified:
		_show_unsaved_dialog_for_action(_do_new_file)
	else:
		_do_new_file()

func _do_new_file() -> void:
	text_edit.text = ""
	current_file_path = ""
	is_modified = false
	_update_title()
	_update_status_bar()

func _open_file() -> void:
	if is_modified:
		_show_unsaved_dialog_for_action(_do_open_file)
	else:
		_do_open_file()

func _do_open_file() -> void:
	var dialog = OSFileDialog.create(OSFileDialog.FileMode.OPEN_FILE)
	dialog.add_filter("Text Files", PackedStringArray(["txt"]))
	dialog.add_filter("GDScript Files", PackedStringArray(["gd"]))
	dialog.add_filter("All Files", PackedStringArray(["*"]))
	
	# Add to window container (parent of the window)
	Global.main_ui.window_container.add_child(dialog)
	
	dialog.file_selected.connect(_on_file_opened)

func _on_file_opened(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		text_edit.text = file.get_as_text()
		current_file_path = path
		is_modified = false
		_update_title()
		_update_status_bar()
	else:
		_show_error("Failed to open file: " + path)

func _save_file() -> void:
	if current_file_path.is_empty():
		_save_file_as()
	else:
		_do_save_file(current_file_path)

func _save_file_as() -> void:
	var dialog = OSFileDialog.create(OSFileDialog.FileMode.SAVE_FILE)
	dialog.add_filter("Text Files", PackedStringArray(["txt"]))
	dialog.add_filter("GDScript Files", PackedStringArray(["gd"]))
	dialog.add_filter("All Files", PackedStringArray(["*"]))
	
	if not current_file_path.is_empty():
		dialog.set_current_file(current_file_path.get_file())
		dialog.set_current_dir(current_file_path.get_base_dir())
		
	Global.main_ui.window_container.add_child(dialog)
	
	dialog.file_selected.connect(_do_save_file)

func _do_save_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(text_edit.text)
		current_file_path = path
		is_modified = false
		_update_title()
		_update_status_bar()
		
		# Show success message
		var success_dialog = OSAcceptDialog.create("File saved successfully!", "OK")
		Global.main_ui.window_container.add_child(success_dialog)
	else:
		_show_error("Failed to save file: " + path)

## Edit Operations

func _undo() -> void:
	text_edit.undo()

func _redo() -> void:
	text_edit.redo()

func _cut() -> void:
	text_edit.cut()

func _copy() -> void:
	text_edit.copy()

func _paste() -> void:
	text_edit.paste()

func _select_all() -> void:
	text_edit.select_all()

func _find() -> void:
	var dialog = OSInputDialog.create("Enter search text:", "", "Search...")
	Global.main_ui.window_container.add_child(dialog)
	
	dialog.text_submitted.connect(_on_find_text)

func _on_find_text(search_text: String) -> void:
	if search_text.is_empty():
		return
	
	var text = text_edit.text
	var start_pos = text_edit.get_caret_column()
	var found_pos = text.find(search_text, start_pos)
	
	if found_pos == -1:
		# Search from beginning
		found_pos = text.find(search_text)
	
	if found_pos != -1:
		# Calculate line and column
		var lines_before = text.substr(0, found_pos).split("\n")
		var line = lines_before.size() - 1
		var col = lines_before[-1].length()
		
		text_edit.set_caret_line(line)
		text_edit.set_caret_column(col)
		text_edit.select(line, col, line, col + search_text.length())
		text_edit.grab_focus()
	else:
		_show_error("Text not found: " + search_text)

## UI Updates

func _update_title() -> void:
	var file_name = "Untitled"
	if not current_file_path.is_empty():
		file_name = current_file_path.get_file()
	
	var modified_mark = "*" if is_modified else ""
	title = "Text Editor - " + file_name + modified_mark

func _update_status_bar() -> void:
	if not current_file_path.is_empty():
		file_name_label.text = current_file_path
	else:
		file_name_label.text = "Untitled"
	
	var line = text_edit.get_caret_line() + 1
	var col = text_edit.get_caret_column() + 1
	line_col_label.text = "Ln %d, Col %d" % [line, col]
	
	modified_indicator.visible = is_modified

## Dialogs

func _show_unsaved_dialog() -> void:
	var dialog = OSConfirmationDialog.create(
		"You have unsaved changes. Do you want to save before closing?",
		"Save",
		"Don't Save"
	)
	dialog.add_button("Cancel", "cancel")
	
	Global.main_ui.window_container.add_child(dialog)
	
	dialog.confirmed.connect(func():
		_save_file()
		# Wait for save dialog if needed
		await get_tree().process_frame
		if not is_modified:
			queue_free()
	)
	
	dialog.canceled.connect(func():
		queue_free()
	)
	
	# Cancel does nothing - just closes the dialog

func _show_unsaved_dialog_for_action(action: Callable) -> void:
	var dialog = OSConfirmationDialog.create(
		"You have unsaved changes. Save before continuing?",
		"Save",
		"Don't Save"
	)
	dialog.add_button("Cancel", "cancel")
	
	Global.main_ui.window_container.add_child(dialog)
	
	dialog.confirmed.connect(func():
		_save_file()
		# Wait for save to complete
		await get_tree().process_frame
		if not is_modified:
			action.call()
	)
	
	dialog.canceled.connect(action)
	
	# Cancel does nothing

func _show_error(message: String) -> void:
	var dialog = OSAcceptDialog.create(message, "OK")
	Global.main_ui.window_container.add_child(dialog)

## Signal Handlers

func _on_text_changed() -> void:
	if not is_modified:
		is_modified = true
		_update_title()
		_update_status_bar()

func _on_caret_changed() -> void:
	_update_status_bar()

func _on_file_menu_pressed(id: int) -> void:
	match id:
		FileMenuId.NEW:
			_new_file()
		FileMenuId.OPEN:
			_open_file()
		FileMenuId.SAVE:
			_save_file()
		FileMenuId.SAVE_AS:
			_save_file_as()
		FileMenuId.CLOSE:
			if can_close():
				queue_free()

func _on_edit_menu_pressed(id: int) -> void:
	match id:
		EditMenuId.UNDO:
			_undo()
		EditMenuId.REDO:
			_redo()
		EditMenuId.CUT:
			_cut()
		EditMenuId.COPY:
			_copy()
		EditMenuId.PASTE:
			_paste()
		EditMenuId.SELECT_ALL:
			_select_all()
		EditMenuId.FIND:
			_find()
