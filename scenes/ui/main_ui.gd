extends CanvasLayer
class_name MainUI

var par: SubViewport
@export var main_menu: Control
@export var computer_ui: Control
@onready var theme: Control = $Theme
@onready var window_container: Control = $Theme/GUI/WindowContainer
@onready var gui = $Theme/GUI
@onready var os_window_scene = preload("res://scenes/ui/window/os_window.tscn")

var active_windows: Array[OSWindow] = []

func _ready() -> void:
	Global.main_ui = self
	par = get_parent() as SubViewport

## Run a program by ID (from ProgramManager)
func run_program_by_id(program_id: String, init_pos: Vector2 = Vector2.ONE * -1, window_size: Vector2 = Vector2(800, 600)) -> OSWindow:
	var prog = ProgramManager.create_program(program_id)
	if not prog:
		push_error("Failed to create program: " + program_id)
		return null
	
	return run_program(prog, init_pos, window_size)

## Run a program instance directly
func run_program(prog: Program, init_pos: Vector2 = Vector2.ONE * -1, window_size: Vector2 = Vector2(0,0)) -> OSWindow:
	var window := os_window_scene.instantiate() as OSWindow
	window_container.add_child(window)
	window.custom_init(window_size, init_pos)
	window.load_program(prog)
	
	active_windows.append(window)
	window.tree_exiting.connect(_on_window_closed.bind(window))
	
	return window

func _on_window_closed(window: OSWindow) -> void:
	var idx = active_windows.find(window)
	if idx >= 0:
		active_windows.remove_at(idx)

func put_on_top(control: Control) -> void:
	var parent = control.get_parent()
	if parent:
		parent.move_child(control, parent.get_child_count())

## Get all running windows for a specific program type
func get_windows_by_program_id(program_id: String) -> Array[OSWindow]:
	var result: Array[OSWindow] = []
	for window in active_windows:
		if window.held_program and window.held_program.program_id == program_id:
			result.append(window)
	return result

## Close all instances of a program
func close_program_instances(program_id: String) -> void:
	var windows = get_windows_by_program_id(program_id)
	for window in windows:
		window.queue_free()


func _on_window_button_pressed(button: WindowButton) -> void:
	print(button.name.to_lower())
	match button.name.to_lower():
		"start":
			run_program(TemplateProgram.new())
		"file":
			pass
