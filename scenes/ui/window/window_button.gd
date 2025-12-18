extends Button
class_name WindowButton

signal window_button_pressed(button:WindowButton)

func _enter_tree() -> void:
	self.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not pressed.is_connected(_on_pressed):
		self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	window_button_pressed.emit(self)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			#self.modulate = Color(1.2, 1.2, 1.2)
		NOTIFICATION_MOUSE_EXIT:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			#self.modulate = Color(1.0, 1.0, 1.0)
