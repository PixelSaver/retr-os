@tool
extends Control
class_name Program

## Emulates _process(delta) function but obeys is_running
signal program_process(delta:float)
## Emitted on program start so subclasses of Program can run specific code
signal program_start()
## Emitted on program end so subclasses of Program can run specific code
signal program_end()
## Emitted when the program scene is loaded
signal program_loaded()

var title: String = ""
var icon: Texture2D = Texture2D.new()
var is_running: bool = false
var has_loaded = false
@export var program_scene : PackedScene = PackedScene.new()
# This tool button doesn't work since the scene is hardcoded in the subclass, and the parent class can't use that
#@export_tool_button("Load Program Scene (Editor)")
#var _editor_load_button : Callable = _editor_load_program_scene

func start_program() -> void:
	is_running = true
	program_start.emit()

func end_program() -> void:
	is_running = false
	program_end.emit()

func load_program_scene():
	if has_loaded: return
	has_loaded = true
	var inst = program_scene.instantiate()
	add_child(inst)
	program_loaded.emit()
	

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_running:
		return
	program_process.emit(delta)

func _editor_load_program_scene() -> void:
	if not Engine.is_editor_hint():
		return

	# Prevent duplicates in editor
	var existing := get_node_or_null("ProgramScene")
	if existing:
		existing.queue_free()

	has_loaded = false
	load_program_scene()
