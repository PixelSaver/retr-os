extends Program
class_name ProgramManagerProgram

@export_group("UI References")
@export var toolbar: HBoxContainer
@export var refresh_button: Button
@export var kill_all_button: Button
@export var process_table: VBoxContainer
@export var header_row: HBoxContainer
@export var program_list: VBoxContainer
@export var status_bar: HBoxContainer
@export var status_label: RichTextLabel

## 0 means shrink, anything above 0 means a ratio of stretching
@export_group("Column Stretch Ratios")
#@export var col_icon_ratio: float = 0
@export var col_name_ratio: float = 2
@export var col_window_ratio: float = 3
@export var col_status_ratio: float = 1
@export var col_button_ratio: float = 0

@export_group("Minimum Sizes")
#@export var col_icon_min: int = 50
@export var col_button_min: int = 100

var running_programs: Array[Program] = []

func _program_ready() -> void:
	title = "Program Manager"
	
	_connect_signals()
	_create_header_row()
	_load_running_programs()
	_update_program_list()

func _create_header_row():
	for child in header_row.get_children():
		child.queue_free()
	
	#TODO Add icon and window if more details / large window? 
	# Icon column (fixed width, shrink)
	#var icon_label = _create_header_label("", col_icon_ratio, col_icon_min)
	#icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#header_row.add_child(icon_label)
	
	# Name column (expands with ratio)
	var name_label = _create_header_label("Program Name", col_name_ratio)
	header_row.add_child(name_label)
	
	# Window column (expands with ratio - largest)
	#var window_label = _create_header_label("Window Title", col_window_ratio)
	#header_row.add_child(window_label)
	
	# Status column (expands with ratio)
	var status_label = _create_header_label("Status", col_status_ratio)
	header_row.add_child(status_label)
	
	# Button column (fixed width, shrink)
	var button_label = _create_header_label("Actions", col_button_ratio, col_button_min)
	header_row.add_child(button_label)

func _create_header_label(text: String, stretch_ratio: float = 1.0, min_size: int = 0) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	
	if stretch_ratio > 0:
		# Expandable column
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = stretch_ratio
	else:
		# Fixed-size column
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		label.custom_minimum_size = Vector2(min_size, 0)
	
	return label

func _create_cell_label(text: String, stretch_ratio: float = 1.0, min_size: int = 0) -> Label:
	var label = Label.new()
	label.text = text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if stretch_ratio > 0:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = stretch_ratio
	else:
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		label.custom_minimum_size = Vector2(min_size, 0)
	
	return label

func _connect_signals() -> void:
	refresh_button.pressed.connect(_refresh_list)
	kill_all_button.pressed.connect(_on_kill_all_pressed)
	
	ProgramManager.running_programs_list_changed.connect(_refresh_list)

func _program_start(args:Array=[]) -> void:
	print("Program Manager started")
	_refresh_list()

func _program_end() -> void:
	print("Program Manager ended")

## Fetches the current list of running Program instances.
func _load_running_programs() -> void:
	running_programs = ProgramManager.running_programs

## Clears and regenerates the list of running programs in the GUI
func _update_program_list() -> void:
	# Clear existing list items
	for child in program_list.get_children():
		child.queue_free()
	
	# Basically never happens since the program manager is a program
	if running_programs.is_empty():
		var label = Label.new()
		label.text = "No programs currently running."
		program_list.add_child(label)
		return
	
	# Populate the list with running programs
	for i in range(running_programs.size()):
		var program: Program = running_programs[i]
		var program_entry = _create_program_list_entry(program, i)
		program_list.add_child(program_entry)
		
		if i < running_programs.size() - 1:
			var sep = HSeparator.new()
			sep.modulate = Color(1, 1, 1, 0.1)
			program_list.add_child(sep)
			
	status_label.text = "%d program%s running" % [running_programs.size(), 
		"s" if running_programs.size() != 1 
		else ""]

## Creates a single entry row for the program list
func _create_program_list_entry(program: Program, index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	panel.add_child(hbox)
	
	# Icon column (fixed, centered)
	#var icon_label = _create_cell_label(_get_program_icon(program), col_icon_ratio, col_icon_min)
	#icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#hbox.add_child(icon_label)
	
	# Name column (expands)
	var prog_name = program.program_id if not program.program_id.is_empty() else program.get_class()
	var name_label = _create_cell_label(prog_name, col_name_ratio)
	hbox.add_child(name_label)
	
	# Window title column (expands - largest)
	#var window_title = program.title if not program.title.is_empty() else "Untitled"
	#var window_label = _create_cell_label(window_title, col_window_ratio)
	#hbox.add_child(window_label)
	
	# Status column (expands)
	var status = "Running" if program.is_running else "Paused"
	var status_label = _create_cell_label(status, col_status_ratio)
	status_label.add_theme_color_override("font_color", Color.GREEN if program.is_running else Color.YELLOW)
	hbox.add_child(status_label)
	
	# Button column (fixed)
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button_container.custom_minimum_size = Vector2(col_button_min, 0)
	button_container.add_theme_constant_override("separation", 4)
	hbox.add_child(button_container)
	
	var end_button = Button.new()
	end_button.text = "End Task"
	end_button.custom_minimum_size = Vector2(90, 25)
	end_button.pressed.connect(_on_kill_button_pressed.bind(index))
	button_container.add_child(end_button)
	
	# Hover
	panel.mouse_entered.connect(func():
		panel.modulate.a = 1.1
	)
	panel.mouse_exited.connect(func():
		panel.modulate.a = 1.0
	)
	
	return panel

func _get_program_icon(program: Program) -> String:
	var prog_id = program.program_id.to_lower()
	#TODO Figure out icons maybe
	return ""

## Signal Handlers

func _refresh_list() -> void:
	_load_running_programs()
	_update_program_list()
	status_label.text = "Refreshed - %d program%s running" % [running_programs.size(), "s" if running_programs.size() != 1 else ""]

## Handles the "End Task" button press

func _on_kill_button_pressed(index: int) -> void:
	if index < 0 or index >= running_programs.size(): return
	
	var program_to_kill: Program = running_programs[index]
	var program_name = program_to_kill.title
	
	# Attempt to close gracefully first
	if program_to_kill.can_close():
		program_to_kill.close_program_window()
		
		status_label.text = "Ended task: %s" % program_name
		
		_refresh_list()
	else:
		status_label.text = "Program '%s' is preventing close (unsaved changes?)" % program_name
		#TODO Might change this to await the can_close signal????

func _on_kill_all_pressed() -> void:
	if running_programs.is_empty():
		return
	
	var confirm = OSConfirmationDialog.create(
		"End all %d running programs?" % running_programs.size(),
		"End All",
		"Cancel"
	)
	Global.main_ui.window_container.add_child(confirm)
	
	confirm.confirmed.connect(_do_kill_all)

func _do_kill_all() -> void:
	var killed_count = 0
	
	# Kill in reverse order
	for i in range(running_programs.size() - 1, -1, -1):
		var program = running_programs[i]
		
		# Skip programs that can't close
		if not program.can_close():
			continue
		
		var window = program.get_window()
		if window:
			window.queue_free()
			killed_count += 1
	
	status_label.text = "Ended %d task%s" % [killed_count, "s" if killed_count != 1 else ""]
	
	_refresh_list()
