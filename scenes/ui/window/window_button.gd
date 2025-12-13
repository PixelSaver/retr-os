extends Button
class_name WindowButton

@onready var texture_rect: TextureRect = $TextureRect
@export_group("Textures")
@export var idle_texture : Texture2D
@export var hover_texture : Texture2D
@export var pressed_texture : Texture2D
var is_pressed := false
var is_hovered := false
signal window_button_pressed(button:WindowButton)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			is_hovered = true
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false

func _process(_delta: float) -> void:
	if is_pressed and Input.is_action_just_released("l_click"):
		is_pressed = false
	if is_pressed:
		texture_rect.texture = pressed_texture
	elif is_hovered:
		texture_rect.texture = hover_texture
	else:
		texture_rect.texture = idle_texture

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("l_click"):
		is_pressed = true
		window_button_pressed.emit(self)
	
	
