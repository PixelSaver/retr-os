extends Control
class_name Program

## Emulates _process(delta) function but obeys is_running
signal program_process(delta:float)
## Emitted on program start so subclasses of Program can run specific code
signal program_start()
## Emitted on program end so subclasses of Program can run specific code
signal program_end()

var title: String = ""
var icon: Texture2D = Texture2D.new()
var is_running: bool = false

func start_program() -> void:
	is_running = true
	program_start.emit()

func end_program() -> void:
	is_running = false
	program_end.emit()

func _process(delta: float) -> void:
	if not is_running:
		return
	program_process.emit(delta)
