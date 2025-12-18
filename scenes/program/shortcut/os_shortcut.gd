extends Control
class_name OSShortcut

@export var program_id: String = "" :
	set(value):
		program_id = value
		call_deferred("_refresh_ui")

@export var icon_texture: Texture2D :
	set(value):
		icon_texture = value
		call_deferred("_refresh_ui")

@export var label_text: String = "" :
	set(value):
		label_text = value
		call_deferred("_refresh_ui")

@onready var icon_texture_rect: TextureRect = $VBoxContainer/MarginContainer/TextureRect
@onready var label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var highlight: ColorRect = $Highlight
var _id : String = ""
var args : Array = []

func _ready() -> void:
	highlight.modulate.a = 0
	if not program_id.is_empty():
		var stuff = program_id.split(" ")
		_id = stuff[0]
		stuff.remove_at(0)
		args = stuff
		_setup_from_program_manager()

func _setup_from_program_manager() -> void:
	var info = ProgramManager.get_program_info(_id)
	if not info.is_empty():
		label_text = info.get("title", _id)
		var info_icon = info.get("icon")
		if not info_icon.is_empty():
			if info_icon == "custom":
				# Use the one set in the editor
				return
			icon_texture = load(info_icon)
		else:
			icon_texture_rect.texture = Texture2D.new().create_placeholder()

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
		Global.main_ui.run_program_by_id(_id, args)
	else:
		push_error("Global.main_ui not set")
		
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if program_id != "empty":
				highlight.modulate.a = 0.3
			else:
				highlight.modulate.a = 0
		NOTIFICATION_MOUSE_EXIT:
			highlight.modulate.a = 0
