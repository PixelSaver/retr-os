extends VBoxContainer
class_name OSFileBrowser

signal file_selected(path: String)
signal files_selected(paths: PackedStringArray)
signal dir_selected(dir: String)
signal file_activated(path: String)
signal selection_changed(selected_paths: PackedStringArray)

## Mode that the file browser is in
enum FileMode {
	OPEN_FILE,
	OPEN_FILES,
	OPEN_DIR,
	SAVE_FILE
}

## Scope of file access
enum Access {
	RESOURCES,
	USERDATA,
	FILESYSTEM,
	GAME
}

# Config stuff
var file_mode: FileMode = FileMode.OPEN_FILE
var access_mode: Access = Access.GAME
var show_hidden_files: bool = false
var show_toolbar: bool = true
var show_sidebar: bool = true
var show_status_bar: bool = true
var allow_file_operations: bool = true

## Filters for searching files
var filters: Array[Dictionary] = []

# State variables
var current_dir: String = ""
var current_items: Array[Dictionary] = []
var selected_items: PackedStringArray = []
var dir_access: DirAccess

## UI References

var toolbar: HBoxContainer
var dir_up_button: Button
var refresh_button: Button
var new_folder_button: Button
var show_hidden_button: Button
var dir_path_edit: LineEdit

var main_hsplit: HSplitContainer
var sidebar: VBoxContainer
var favorites_list: ItemList
var drives_list: ItemList

var file_list: ItemList
var filename_container: HBoxContainer
var filename_edit: LineEdit
var filter_option: OptionButton

var status_bar: HBoxContainer
var status_label: Label
var item_count_label: Label

var context_menu: PopupMenu

static var global_favorites: PackedStringArray = [
	"user://game_files",
	"res://",
	"user://",
	#TODO Add a game file directory
]
const OS_FILE_DIALOG = preload("uid://q0n1glrx3cko")

func _ready() -> void:
	_setup_game_dir()
	_build_ui()
	_setup_context_menu()
	_connect_signals()
	
	# Set initial directory if not set
	if current_dir.is_empty():
		match access_mode:
			Access.RESOURCES:
				current_dir = "res://"
			Access.USERDATA:
				current_dir = "user://"
			Access.GAME:
				current_dir = "user://game_files"
			Access.FILESYSTEM:
				current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	open_directory(current_dir)

## Setup for the user://game_files directory
func _setup_game_dir():
	var dir = DirAccess.open("user://")
	if dir.dir_exists("game_files"): return
	dir.make_dir("game_files")

func _build_ui() -> void:
	if show_toolbar:
		toolbar = HBoxContainer.new()
		toolbar.add_theme_constant_override("separation", 4)
		add_child(toolbar)
		
		dir_up_button = Button.new()
		dir_up_button.text = "↑"
		dir_up_button.tooltip_text = "Parent directory"
		dir_up_button.custom_minimum_size = Vector2(40, 0)
		toolbar.add_child(dir_up_button)
		
		dir_path_edit = LineEdit.new()
		dir_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toolbar.add_child(dir_path_edit)
		
		refresh_button = Button.new()
		refresh_button.text = "⟳"
		refresh_button.tooltip_text = "Refresh"
		refresh_button.custom_minimum_size = Vector2(40, 0)
		toolbar.add_child(refresh_button)
		
		if allow_file_operations:
			new_folder_button = Button.new()
			new_folder_button.text = "📁+"
			new_folder_button.tooltip_text = "New Folder"
			new_folder_button.custom_minimum_size = Vector2(50, 0)
			toolbar.add_child(new_folder_button)
		
		show_hidden_button = Button.new()
		show_hidden_button.text = "👁"
		show_hidden_button.tooltip_text = "Show hidden files"
		show_hidden_button.toggle_mode = true
		show_hidden_button.custom_minimum_size = Vector2(40, 0)
		toolbar.add_child(show_hidden_button)
	
	# Main content with optional sidebar
	if show_sidebar:
		main_hsplit = HSplitContainer.new()
		main_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(main_hsplit)
		
		# Sidebar
		sidebar = VBoxContainer.new()
		sidebar.custom_minimum_size = Vector2(120, 0)
		main_hsplit.add_child(sidebar)
		
		var favorites_label = Label.new()
		favorites_label.text = "Favorites"
		sidebar.add_child(favorites_label)
		
		favorites_list = ItemList.new()
		favorites_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sidebar.add_child(favorites_list)
		_update_favorites()
		
		var drives_label = Label.new()
		drives_label.text = "Drives"
		sidebar.add_child(drives_label)
		
		drives_list = ItemList.new()
		drives_list.custom_minimum_size = Vector2(0, 100)
		sidebar.add_child(drives_list)
		_update_drives()
		
		# File list in split
		file_list = ItemList.new()
		file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		file_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_hsplit.add_child(file_list)
	else:
		# File list without sidebar
		file_list = ItemList.new()
		file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		file_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(file_list)
	
	file_list.allow_reselect = true
	
	# Set select mode based on file mode
	match file_mode:
		FileMode.OPEN_FILES:
			file_list.select_mode = ItemList.SELECT_MULTI
		_:
			file_list.select_mode = ItemList.SELECT_SINGLE
	
	# Filename input (for SAVE_FILE and OPEN_FILE modes)
	if file_mode in [FileMode.OPEN_FILE, FileMode.SAVE_FILE]:
		filename_container = HBoxContainer.new()
		filename_container.add_theme_constant_override("separation", 8)
		add_child(filename_container)
		
		var filename_label = Label.new()
		filename_label.text = "File:"
		filename_label.custom_minimum_size = Vector2(40, 0)
		filename_container.add_child(filename_label)
		
		filename_edit = LineEdit.new()
		filename_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filename_container.add_child(filename_edit)
		
		if filters.size() > 0:
			var filter_label = Label.new()
			filter_label.text = "Type:"
			filename_container.add_child(filter_label)
			
			filter_option = OptionButton.new()
			filter_option.custom_minimum_size = Vector2(150, 0)
			filename_container.add_child(filter_option)
			_update_filter_list()
	
	# Status bar
	if show_status_bar:
		status_bar = HBoxContainer.new()
		add_child(status_bar)
		
		status_label = Label.new()
		status_label.text = "Ready"
		status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_bar.add_child(status_label)
		
		item_count_label = Label.new()
		item_count_label.text = "0 items"
		status_bar.add_child(item_count_label)
	
func _update_drives() -> void:
	if not drives_list:
		return
	
	drives_list.clear()
	drives_list.add_item("📁 Documents")
	
	if OS.get_name() == "Windows":
		for letter in ["C", "D", "E", "F"]:
			var drive = letter + ":\\"
			if DirAccess.dir_exists_absolute(drive):
				drives_list.add_item("💾 " + letter + ":")

func _connect_signals() -> void:
	if toolbar:
		dir_up_button.pressed.connect(_on_dir_up)
		refresh_button.pressed.connect(refresh)
		dir_path_edit.text_submitted.connect(_on_path_submitted)
		show_hidden_button.toggled.connect(_on_show_hidden_toggled)
		if new_folder_button:
			new_folder_button.pressed.connect(_on_new_folder_requested)
	
	if sidebar:
		favorites_list.item_selected.connect(_on_favorite_selected)
		drives_list.item_selected.connect(_on_drive_selected)
	
	file_list.item_selected.connect(_on_file_selected)
	file_list.item_activated.connect(_on_file_activated)
	file_list.empty_clicked.connect(_on_empty_clicked)
	file_list.item_clicked.connect(_on_item_clicked)
	
	if file_mode == FileMode.OPEN_FILES:
		file_list.multi_selected.connect(_on_file_multi_selected)
	
	if filename_edit:
		filename_edit.text_changed.connect(_on_filename_changed)
	
	if filter_option:
		filter_option.item_selected.connect(_on_filter_changed)
	
	if context_menu:
		context_menu.id_pressed.connect(_on_context_menu_item)

func _setup_context_menu() -> void:
	if not allow_file_operations:
		return
	
	context_menu = PopupMenu.new()
	add_child(context_menu)
	
	context_menu.add_item("Open", 0)
	context_menu.add_separator()
	context_menu.add_item("Copy Path", 1)
	context_menu.add_item("Rename", 2)
	context_menu.add_item("Delete", 3)
	context_menu.add_separator()
	context_menu.add_item("New Folder", 4)

func _setup_initial_dir() -> void:
	if current_dir.is_empty():
		match access_mode:
			Access.RESOURCES:
				current_dir = "res://"
			Access.USERDATA:
				current_dir = "user://"
			Access.GAME:
				current_dir = "user://game_files"
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
	selected_items.clear()
	
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
	
	# Add parent directory if not at root
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
		var icon = _get_file_icon(file)
		file_list.add_item(icon + " " + file)
		current_items.append({
			"name": file,
			"is_dir": false,
			"path": full_path
		})
	
	_update_status_bar()

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

func _get_file_icon(file_name: String) -> String:
	#TODO Chnage the file icons to actual images instead of emojis (web export doesn't allow it)
	var ext = file_name.get_extension().to_lower()
	match ext:
		"txt", "md":
			return "📝"
		"gd", "py", "js", "cpp", "h":
			return "📜"
		"png", "jpg", "jpeg", "gif", "bmp":
			return "🖼️"
		"mp3", "wav", "ogg":
			return "🎵"
		"mp4", "avi", "mkv":
			return "🎬"
		"zip", "rar", "7z":
			return "📦"
		_:
			return "📄"

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

func _update_status_bar() -> void:
	if not status_bar:
		return
	
	var file_count = 0
	var dir_count = 0
	
	for item in current_items:
		if item.name == "..":
			continue
		if item.is_dir:
			dir_count += 1
		else:
			file_count += 1
	
	var status_text = ""
	if dir_count > 0:
		status_text += str(dir_count) + " folder" + ("s" if dir_count != 1 else "")
	if file_count > 0:
		if not status_text.is_empty():
			status_text += ", "
		status_text += str(file_count) + " file" + ("s" if file_count != 1 else "")
	
	item_count_label.text = status_text if not status_text.is_empty() else "Empty"
	
	if selected_items.size() > 0:
		_set_status(str(selected_items.size()) + " selected")
	else:
		_set_status("Ready")

func _set_status(text: String, is_error: bool = false) -> void:
	if status_label:
		status_label.text = text

## Public API

func open_directory(path: String) -> void:
	dir_access = DirAccess.open(path)
	if not dir_access:
		_set_status("Failed to open directory: " + path, true)
		return
	
	current_dir = path
	if dir_path_edit:
		dir_path_edit.text = current_dir
	_update_file_list()

func refresh() -> void:
	open_directory(current_dir)

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

func get_selected_file() -> String:
	return selected_items[0] if selected_items.size() > 0 else ""

func get_selected_files() -> PackedStringArray:
	return selected_items

func get_current_dir() -> String:
	return current_dir

func set_current_dir(path: String) -> void:
	current_dir = path
	dir_access = DirAccess.open(current_dir)
	if dir_access and file_list:
		_update_file_list()

func set_current_file(file_name: String) -> void:
	if filename_edit:
		filename_edit.text = file_name

## Signal Handlers
func _on_dir_up() -> void:
	if current_dir != _get_root_path():
		open_directory(current_dir.get_base_dir())

func _on_path_submitted(new_path: String) -> void:
	if DirAccess.dir_exists_absolute(new_path):
		open_directory(new_path)
	else:
		_set_status("Directory not found: " + new_path, true)
		if dir_path_edit:
			dir_path_edit.text = current_dir

func _on_show_hidden_toggled(toggled: bool) -> void:
	show_hidden_files = toggled
	refresh()

func _on_favorite_selected(index: int) -> void:
	if index >= 0 and index < global_favorites.size():
		open_directory(global_favorites[index])

func _on_drive_selected(index: int) -> void:
	match index:
		0:
			open_directory(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
		_:
			if OS.get_name() == "Windows":
				var drive_index = index - 1
				var letters = ["C", "D", "E", "F"]
				if drive_index >= 0 and drive_index < letters.size():
					open_directory(letters[drive_index] + ":\\")

func _on_file_selected(index: int) -> void:
	if index < 0 or index >= current_items.size():
		return
	
	var item = current_items[index]
	selected_items = [item.path]
	
	if filename_edit and not item.is_dir:
		filename_edit.text = item.name
	
	selection_changed.emit(selected_items)
	_update_status_bar()

func _on_file_multi_selected(index: int, selected: bool) -> void:
	if index < 0 or index >= current_items.size():
		return
	
	var item = current_items[index]
	
	if selected:
		if not item.path in selected_items:
			selected_items.append(item.path)
	else:
		var idx = selected_items.find(item.path)
		if idx >= 0:
			selected_items.remove_at(idx)
	
	selection_changed.emit(selected_items)
	_update_status_bar()

func _on_file_activated(index: int) -> void:
	if index < 0 or index >= current_items.size():
		return
	
	var item = current_items[index]
	
	if item.is_dir:
		open_directory(item.path)
	else:
		file_activated.emit(item.path)
		
		# Emit appropriate selection signal based on mode
		match file_mode:
			FileMode.OPEN_FILE:
				file_selected.emit(item.path)
			FileMode.OPEN_FILES:
				files_selected.emit(selected_items)

func _on_empty_clicked(_pos: Vector2, _button: int) -> void:
	file_list.deselect_all()
	selected_items.clear()
	selection_changed.emit(selected_items)
	_update_status_bar()

func _on_item_clicked(index: int, at_position: Vector2, mouse_button: int) -> void:
	if mouse_button == MOUSE_BUTTON_RIGHT and context_menu:
		context_menu.position = get_viewport().get_mouse_position()
		context_menu.popup()

func _on_filename_changed(new_text: String) -> void:
	# Update selection when typing in filename
	pass

func _on_filter_changed(_index: int) -> void:
	refresh()

func _on_new_folder_requested() -> void:
	# Emit signal for parent to handle
	pass

func _on_context_menu_item(id: int) -> void:
	match id:
		0: # Open
			if selected_items.size() > 0:
				var item_path = selected_items[0]
				for item in current_items:
					if item.path == item_path:
						if item.is_dir:
							open_directory(item.path)
						else:
							file_activated.emit(item.path)
						break
		1: # Copy Path
			if selected_items.size() > 0:
				DisplayServer.clipboard_set(selected_items[0])
				_set_status("Path copied to clipboard")
