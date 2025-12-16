extends Control
class_name OSShortcut

@export var program_id: String = "" :
	set(value):
		program_id = value

@export var icon_texture: Texture2D :
	set(value):
		icon_texture = value

@export var label_text: String = "" :
	set(value):
		label_text = value

@onready var button: Button = $Button
@onready var icon_texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var label: RichTextLabel = $VBoxContainer/RichTextLabel

func _ready() -> void:
	_refresh_ui()

# UI

func _refresh_ui() -> void:
	if not is_node_ready():
		return

	if icon_texture:
		icon_texture_rect.texture = icon_texture

	if label:
		label.text = label_text

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and event.double_click:
			_on_double_click()

func _on_double_click() -> void:
	if program_id.is_empty():
		push_warning("OSShortcut has no program_id set")
		return

	if Global.main_ui:
		Global.main_ui.run_program_by_id(program_id)
	else:
		push_error("Global.main_ui not set")
