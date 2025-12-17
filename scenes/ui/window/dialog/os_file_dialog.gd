extends OSDialog
class_name OSFileDialog

signal file_selected(path: String)
signal files_selected(paths: PackedStringArray)
signal dir_selected(dir: String)

enum FileMode {
	OPEN_FILE,
	OPEN_FILES,
	OPEN_DIR,
	SAVE_FILE
}

enum Access {
	RESOURCES,
	USERDATA,
	FILESYSTEM
}

var file_mode: FileMode = FileMode.OPEN_FILE
var access_mode: Access = Access.FILESYSTEM
var current_dir: String = ""
var current_file: String = ""
var filters: Array[Dictionary] = []
var show_hidden_files: bool = false

## UI References
var dir_path_edit: LineEdit
var dir_up_button: Button
var refresh_button: Button
var show_hidden_button: Button
var favorites_list: ItemList
var file_list: ItemList
var filename_edit: LineEdit
var filter_option: OptionButton
var ok_button: Button
var cancel_button: Button

var dir_access: DirAccess
var current_items: Array[Dictionary] = []
var selected_files: PackedStringArray = []

static var global_favorites: PackedStringArray = [
	"res://",
	"user://",
]
const OS_FILE_DIALOG = preload("uid://q0n1glrx3cko")

static func create(mode: FileMode = FileMode.OPEN_FILE) -> OSFileDialog:
	var dialog = OS_FILE_DIALOG.instantiate()
	dialog.file_mode = mode
	dialog.is_modal = true
	return dialog

func _ready() -> void:
	super._ready()
	title_label.text = "File Explorer"
	
	_build_dialog()
	_setup_initial_dir()
	_update_file_list()

func _build_dialog() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	program_container.add_child(vbox)
	
	# Navigation bar
	var nav_bar = HBoxContainer.new()
	nav_bar.add_theme_constant_override("separation", 4)
	vbox.add_child(nav_bar)
	
	dir_up_button = Button.new()
	dir_up_button.text = "↑"
	dir_up_button.tooltip_text = "Parent directory"
	dir_up_button.custom_minimum_size = Vector2(40, 0)
	nav_bar.add_child(dir_up_button)
	dir_up_button.pressed.connect(_on_dir_up)
	
	dir_path_edit = LineEdit.new()
	dir_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_bar.add_child(dir_path_edit)
	dir_path_edit.text_submitted.connect(_on_path_submitted)
	
	refresh_button = Button.new()
	refresh_button.text = "⟳"
	refresh_button.tooltip_text = "Refresh"
	refresh_button.custom_minimum_size = Vector2(40, 0)
	nav_bar.add_child(refresh_button)
	refresh_button.pressed.connect(_update_file_list)
	
	show_hidden_button = Button.new()
	show_hidden_button.text = "👁"
	show_hidden_button.tooltip_text = "Show hidden files"
	show_hidden_button.toggle_mode = true
	show_hidden_button.custom_minimum_size = Vector2(40, 0)
	nav_bar.add_child(show_hidden_button)
	show_hidden_button.toggled.connect(_on_show_hidden_toggled)
	
	# Main content area
	var hsplit = HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hsplit)
	
	# Favorites sidebar
	favorites_list = ItemList.new()
	favorites_list.custom_minimum_size = Vector2(80, 150)
	hsplit.add_child(favorites_list)
	favorites_list.item_selected.connect(_on_favorite_selected)
	_update_favorites()
	
	# File list
	file_list = ItemList.new()
	file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	file_list.allow_reselect = true
	hsplit.add_child(file_list)
	file_list.item_selected.connect(_on_file_selected)
	file_list.item_activated.connect(_on_file_activated)
	
	# Update select mode based on file mode
	if file_mode == FileMode.OPEN_FILES:
		file_list.select_mode = ItemList.SELECT_MULTI
		file_list.multi_selected.connect(_on_file_multi_selected)
	
	# Bottom section
	var bottom_vbox = VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(bottom_vbox)
	
	# Filename input
	var filename_hbox = HBoxContainer.new()
	filename_hbox.add_theme_constant_override("separation", 8)
	bottom_vbox.add_child(filename_hbox)
	
	var filename_label = Label.new()
	filename_label.text = "File:"
	filename_label.custom_minimum_size = Vector2(30, 0)
	filename_hbox.add_child(filename_label)
	
	filename_edit = LineEdit.new()
	filename_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filename_hbox.add_child(filename_edit)
	filename_edit.text_changed.connect(_on_filename_changed)
	
	var filter_label = Label.new()
	filter_label.text = "Type:"
	filename_hbox.add_child(filter_label)
	
	filter_option = OptionButton.new()
	filter_option.custom_minimum_size = Vector2(150, 0)
	filename_hbox.add_child(filter_option)
	filter_option.item_selected.connect(_on_filter_changed)
	_update_filter_list()
	
	# Action buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_END
	button_hbox.add_theme_constant_override("separation", 8)
	bottom_vbox.add_child(button_hbox)
	
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 30)
	button_hbox.add_child(cancel_button)
	cancel_button.pressed.connect(func(): close_dialog("cancel"))
	
	ok_button = Button.new()
	ok_button.custom_minimum_size = Vector2(80, 30)
	button_hbox.add_child(ok_button)
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Set OK button text based on mode
	match file_mode:
		FileMode.OPEN_FILE, FileMode.OPEN_FILES:
			ok_button.text = "Open"
		FileMode.OPEN_DIR:
			ok_button.text = "Select"
		FileMode.SAVE_FILE:
			ok_button.text = "Save"
	
	# Set window properties
	custom_init(Vector2(30, 30))

func _setup_initial_dir() -> void:
	if current_dir.is_empty():
		match access_mode:
			Access.RESOURCES:
				current_dir = "res://"
			Access.USERDATA:
				current_dir = "user://"
			Access.FILESYSTEM:
				current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	dir_access = DirAccess.open(current_dir)
	if not dir_access:
		push_error("Failed to open directory: " + current_dir)
		current_dir = "res://"
		dir_access = DirAccess.open(current_dir)

func _update_file_list() -> void:
	file_list.clear()
	current_items.clear()
	
	if not dir_access:
		return
	
	dir_access.list_dir_begin()
	var file_name = dir_access.get_next()
	
	var dirs: Array[String] = []
	var files: Array[String] = []
	
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir_access.get_next()
			continue
		
		if not show_hidden_files and file_name.begins_with("."):
			file_name = dir_access.get_next()
			continue
		
		if dir_access.current_is_dir():
			dirs.append(file_name)
		else:
			if _matches_filter(file_name):
				files.append(file_name)
		
		file_name = dir_access.get_next()
	
	dir_access.list_dir_end()
	
	dirs.sort()
	files.sort()
	
	# Add parent directory option if not at root
	if current_dir != _get_root_path():
		file_list.add_item("..")
		current_items.append({
			"name": "..",
			"is_dir": true,
			"path": current_dir.get_base_dir()
		})
	
	# Add directories
	for dir in dirs:
		var full_path = current_dir.path_join(dir)
		file_list.add_item("📁 " + dir)
		current_items.append({
			"name": dir,
			"is_dir": true,
			"path": full_path
		})
	
	# Add files
	for file in files:
		var full_path = current_dir.path_join(file)
		file_list.add_item("📄 " + file)
		current_items.append({
			"name": file,
			"is_dir": false,
			"path": full_path
		})
	
	dir_path_edit.text = current_dir

func _matches_filter(file_name: String) -> bool:
	if filters.is_empty():
		return true
	
	var selected_idx = filter_option.selected
	if selected_idx < 0 or selected_idx >= filters.size():
		return true
	
	var filter = filters[selected_idx]
	for ext in filter.extensions:
		if ext == "*":
			return true
		if file_name.get_extension() == ext:
			return true
	
	return false

func _get_root_path() -> String:
	match access_mode:
		Access.RESOURCES:
			return "res://"
		Access.USERDATA:
			return "user://"
		Access.FILESYSTEM:
			return "/" if OS.get_name() != "Windows" else "C:\\"
	return "/"

func _update_favorites() -> void:
	favorites_list.clear()
	for fav in global_favorites:
		var display_name = fav
		if fav == "res://":
			display_name = "🎮 Project"
		elif fav == "user://":
			display_name = "👤 User"
		else:
			display_name = "📁 " + fav.get_file()
		
		favorites_list.add_item(display_name)

func _update_filter_list() -> void:
	filter_option.clear()
	if filters.is_empty():
		filter_option.add_item("All Files (*)")
	else:
		for filter in filters:
			var ext_str = ", ".join(filter.extensions)
			filter_option.add_item("%s (%s)" % [filter.description, ext_str])

## Public API

func add_filter(description: String, extensions: PackedStringArray) -> void:
	filters.append({
		"description": description,
		"extensions": extensions
	})
	if filter_option:
		_update_filter_list()

func clear_filters() -> void:
	filters.clear()
	if filter_option:
		_update_filter_list()

func set_current_dir(path: String) -> void:
	current_dir = path
	dir_access = DirAccess.open(current_dir)
	if dir_access and file_list:
		_update_file_list()

func set_current_file(file: String) -> void:
	current_file = file
	if filename_edit:
		filename_edit.text = file

## Signal Handlers

func _on_dir_up() -> void:
	if current_dir != _get_root_path():
		set_current_dir(current_dir.get_base_dir())

func _on_path_submitted(new_path: String) -> void:
	if DirAccess.dir_exists_absolute(new_path):
		set_current_dir(new_path)

func _on_show_hidden_toggled(toggled: bool) -> void:
	show_hidden_files = toggled
	_update_file_list()

func _on_favorite_selected(index: int) -> void:
	if index >= 0 and index < global_favorites.size():
		set_current_dir(global_favorites[index])

func _on_file_selected(index: int) -> void:
	if index < 0 or index >= current_items.size():
		return
	
	var item = current_items[index]
	if not item.is_dir:
		filename_edit.text = item.name
		selected_files = PackedStringArray([item.path])

func _on_file_multi_selected(index: int, selected: bool) -> void:
	if index < 0 or index >= current_items.size():
		return
	
	var item = current_items[index]
	if item.is_dir:
		return
	
	if selected:
		if not item.path in selected_files:
			selected_files.append(item.path)
	else:
		var idx = selected_files.find(item.path)
		if idx >= 0:
			selected_files.remove_at(idx)

func _on_file_activated(index: int) -> void:
	if index < 0 or index >= current_items.size():
		return
	
	var item = current_items[index]
	if item.is_dir:
		set_current_dir(item.path)
	else:
		_on_ok_pressed()

func _on_filename_changed(new_text: String) -> void:
	current_file = new_text

func _on_filter_changed(_index: int) -> void:
	_update_file_list()

func _on_ok_pressed() -> void:
	match file_mode:
		FileMode.OPEN_FILE:
			if not filename_edit.text.is_empty():
				var path = current_dir.path_join(filename_edit.text)
				if FileAccess.file_exists(path):
					file_selected.emit(path)
					close_dialog("ok")
		
		FileMode.OPEN_FILES:
			if not selected_files.is_empty():
				files_selected.emit(selected_files)
				close_dialog("ok")
		
		FileMode.OPEN_DIR:
			dir_selected.emit(current_dir)
			close_dialog("ok")
		
		FileMode.SAVE_FILE:
			if not filename_edit.text.is_empty():
				var path = current_dir.path_join(filename_edit.text)
				# Check if file exists for overwrite warning
				if FileAccess.file_exists(path):
					_show_overwrite_dialog(path)
				else:
					file_selected.emit(path)
					close_dialog("ok")

func _show_overwrite_dialog(path: String) -> void:
	var confirm = OSConfirmationDialog.create("File already exists. Overwrite?", "Overwrite", "Cancel")
	get_parent_control().add_child(confirm)
	
	confirm.confirmed.connect(func():
		file_selected.emit(path)
		close_dialog("ok")
	)
