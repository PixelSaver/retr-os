extends Control
class_name Program

signal program_end
signal program_start
signal program_process(delta:float)
var title: String = "Program"
var icon: Texture2D
var is_running: bool = false
var program_id: String = "" ## Automatically set by the system

## Override this in subclasses for initialization
func _program_ready() -> void:
	pass

## Override this in subclasses for start logic
func _program_start() -> void:
	pass

## Override this in subclasses for end logic  
func _program_end() -> void:
	pass

## Override this in subclasses for per-frame logic
func _program_process(delta: float) -> void:
	pass

func start_program() -> void:
	if not is_running:
		is_running = true
		_program_start()
		program_start.emit()

func end_program() -> void:
	if is_running:
		is_running = false
		_program_end()
		program_end.emit()

func _ready() -> void:
	_program_ready()

func _process(delta: float) -> void:
	if is_running:
		_program_process(delta)
		program_process.emit()
