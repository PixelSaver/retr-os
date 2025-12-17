extends RigidBody3D
class_name RadioMenuButton

signal pressed()
@export var outline_component : OutlineComponent
@export var mesh : MeshInstance3D
var og_rotation : Vector3
var og_pos : Vector3
var t : Tween
var hovered := false

func _ready() -> void:
	og_rotation = rotation
	og_pos = global_position

func _input(event: InputEvent) -> void:
	if not hovered: return
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			is_pressed()

func is_pressed():
	if t: t.kill()
	t = create_tween().set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.set_parallel(true)
	
	t.tween_property(self, "rotation", og_rotation + Vector3(-1, 0, 0) * .6, 0.1)
	t.tween_property(self, "global_position", og_pos + Vector3(0, 1, 0) * .01, 0.1)
	
	pressed.emit()

func unpress():
	if t: t.kill()
	t = create_tween().set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.set_parallel(true)
	
	t.tween_property(self, "rotation", og_rotation, 0.1)
	t.tween_property(self, "global_position", og_pos, 0.1)
	

func _on_mouse_entered():
	outline_component.outline_parent(true)
	hovered = true

func _on_mouse_exited() -> void:
	outline_component.outline_parent(false)
	hovered = false
