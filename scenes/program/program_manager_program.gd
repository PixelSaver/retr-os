extends Program
class_name ProgramManagerProgram

# The path to your ProgramManager autoload/global script (adjust as necessary)
const PROGRAM_MANAGER_PATH = "res://autoloads/ProgramManager.gd" # Adjust this path

@onready var program_list: VBoxContainer = $VBoxContainer/ScrollContainer/ProgramList
@onready var refresh_button: Button = $VBoxContainer/HBoxContainer/RefreshButton

# Assume a global reference for running programs is available. 
# You will need to replace `Global.get_running_programs()` 
# with the actual method in your environment.
# Since you provided ProgramManager, I'll assume your environment 
# tracks the *active* instances separately, for example, 
# in a singleton called 'Global' which manages the windows/desktop.
# For simplicity, I'll define a function to mock this data source 
# if you don't have it yet.
var running_programs: Array[Program] = []

func _program_ready() -> void:
	title = "Program Manager"
	refresh_button.text = "Refresh List"
	refresh_button.pressed.connect(_refresh_list)
	
	_load_running_programs()
	_update_program_list_gui()

func _program_start() -> void:
	print("Program Manager started")
	# Initial update on start
	_refresh_list()

func _program_end() -> void:
	print("Program Manager ended")

## Fetches the current list of running Program instances.
func _load_running_programs() -> void:
	running_programs = ProgramManager.running_programs

## Clears and regenerates the list of running programs in the GUI
func _update_program_list_gui() -> void:
	# Clear existing list items
	for child in program_list.get_children():
		child.queue_free()
	
	# Add a header for the list (optional)
	var header = _create_program_list_entry("Program Name", "Status", -1, true)
	program_list.add_child(header)
	
	if running_programs.is_empty():
		var label = Label.new()
		label.text = "No programs currently running."
		program_list.add_child(label)
		return
	
	# Populate the list with running programs
	for i in range(running_programs.size()):
		var program: Program = running_programs[i]
		var program_entry = _create_program_list_entry(
			program.title,
			"Running", # Simple status
			i
		)
		program_list.add_child(program_entry)

## Creates a single entry row for the program list
func _create_program_list_entry(name: String, status: String, index: int, is_header: bool = false) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND
	
	var name_label = Label.new()
	name_label.text = name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND
	name_label.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(name_label)
	
	var status_label = Label.new()
	status_label.text = status
	status_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(status_label)
	
	if is_header:
		# Headers don't have a Kill button
		name_label.add_theme_font_size_override("font_size", 16)
		status_label.add_theme_font_size_override("font_size", 16)
	else:
		var kill_button = Button.new()
		kill_button.text = "End Task"
		kill_button.custom_minimum_size = Vector2(80, 0)
		kill_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		# Use a Callable to pass the program index
		kill_button.pressed.connect(Callable(self, "_on_kill_button_pressed").bind(index))
		hbox.add_child(kill_button)
	
	return hbox

## Signal Handlers

func _refresh_list() -> void:
	_load_running_programs()
	_update_program_list_gui()

## Handles the "End Task" button press
func _on_kill_button_pressed(index: int) -> void:
	if index < 0 or index >= running_programs.size():
		return # Index out of bounds
	
	var program_to_kill: Program = running_programs[index]
	var program_name = program_to_kill.title
	
	# Attempt to close gracefully first, then force-kill if needed.
	# Since your TextEditorProgram has a can_close(), we'll use that.
	if program_to_kill.can_close():
		print("Attempting to close program: %s" % program_name)
		program_to_kill.close_program_window()
		
		print("Killed program: %s" % program_name)
		
		# Immediately refresh the list after killing a program
		_refresh_list()
	else:
		# If can_close() returns false, it means the program is showing
		# a dialog (like 'unsaved changes'). We can't force close from 
		# here without bypassing the program's logic.
		print("Program %s is preventing immediate close (e.g., unsaved changes dialog)." % program_name)
		# You might want to force kill here by calling program_to_kill.queue_free() 
		# regardless of the can_close() return, but that is generally bad practice.
