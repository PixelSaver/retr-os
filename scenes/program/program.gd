extends Control
class_name Program

signal program_end
signal program_start
signal program_process(delta:float)
signal close_window
signal minimize_window
signal fullscreen_window
signal title_changed
var title: String = "Program"
var icon: Texture2D
var is_running: bool = false
var program_id: String = ""
## Flag to check if the program can close or if it needs to finish an operation before closing
var is_closable: bool = true
@export var min_size:Vector2 = Vector2.ONE*-1

## Override this in subclasses for initialization
func _program_ready() -> void:
	pass

## Override this in subclasses for start logic
func _program_start(args:Array=[]) -> void:
	pass

## Override this in subclasses for end logic
## By default, closes the window and frees the program
func _program_end() -> void:
	queue_free()
	
func _close_window():
	close_window.emit()

## Override this in subclasses for per-frame logic
func _program_process(delta: float) -> void:
	pass

## Returns true by default, can be overridden by subclasses
func can_close() -> bool:
	return is_closable

func close_program_window():
	close_window.emit()

func start_program() -> void:
	if not is_running:
		is_running = true
		ProgramManager.add_running_program(self)
		_program_start()
		program_start.emit()

func end_program() -> void:
	if is_running:
		is_running = false
		ProgramManager.remove_running_program(self)
		program_end.emit()

func _ready() -> void:
	_program_ready()

func _process(delta: float) -> void:
	if is_running:
		_program_process(delta)
		program_process.emit()
