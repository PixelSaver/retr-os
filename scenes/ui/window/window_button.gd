extends Button
class_name WindowButton

signal window_button_pressed(button:WindowButton)

func _on_pressed() -> void:
	window_button_pressed.emit(self)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			self.modulate = Color(1.2, 1.2, 1.2)
		NOTIFICATION_MOUSE_EXIT:
			self.modulate = Color(1.0, 1.0, 1.0)
