extends Control
class_name UI

@export var button : Button
var t : Tween

func _ready() -> void:
	button.pivot_offset = Vector2(0, button.size.y / 2)
	Global.game_state_changed.connect(_on_state_change)

func _on_button_mouse_entered() -> void:
	if t: t.kill()
	t = create_tween().set_ease(Tween.EASE_OUT)
	t.set_parallel(true).set_trans(Tween.TRANS_QUINT)
	t.tween_property(button, "scale", Vector2.ONE * 1.1, 0.3)
	t.tween_property(button, "modulate", Color.SANDY_BROWN, 0.3)
func _on_button_mouse_exited() -> void:
	if t: t.kill()
	t = create_tween().set_ease(Tween.EASE_OUT)
	t.set_parallel(true).set_trans(Tween.TRANS_QUINT)
	t.tween_property(button, "scale", Vector2.ONE, 0.3)
	t.tween_property(button, "modulate", Color.WHITE, 0.3)


func _on_button_pressed() -> void:
	get_tree().quit()
	pass
	#if t: t.kill()
	#t = create_tween().set_ease(Tween.EASE_OUT)
	#t.set_parallel(true).set_trans(Tween.TRANS_QUINT)
	#t.tween_property(self, "modulate:a", 0, 0.3)
	#t.tween_property(button, "scale", Vector2.ONE, 0.3)
func _on_state_change(new_state:int):
	if t: t.kill()
	t = create_tween().set_ease(Tween.EASE_OUT)
	t.set_parallel(true).set_trans(Tween.TRANS_QUINT)
	t.tween_property(self, "modulate:a", 0, 0.3)
	t.tween_property(button, "scale", Vector2.ONE, 0.3)
	await t.finished
	hide()
		
