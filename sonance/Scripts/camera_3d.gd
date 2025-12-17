extends Camera3D

@export var ray : RayCast3D
@export var canvas_target : Marker3D
@export var control : Control
@export var flashlight : SpotLight3D
var target : Vector3 = Vector3(0,0,1)

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 100
	ray.global_position = from
	ray.target_position = to
	
	target = lerp(target, to, delta * 3)
	flashlight.look_at(Vector3(target.x/2, target.y, target.z), Vector3.UP)
