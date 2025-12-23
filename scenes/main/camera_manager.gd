extends Node3D
class_name CameraManager

signal camera_tween_finished
@export_group("Markers")
@export var marker_array : Array[Marker3D] 
var target_transform : Transform3D
var camera : Camera3D 
var t : Tween

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	target_transform = camera.get_global_transform()
	Global.cam_to_marker.connect(cam_to_marker)

func cam_to_marker(which:String):
	print("Tweening")
	for marker in marker_array:
		if marker.name.to_lower() == which.to_lower():
			target_transform = marker.global_transform
			_tween_cam()

func _tween_cam():
	if t and t.is_valid(): t.kill()
	t = create_tween().set_trans(Tween.TRANS_QUINT)
	t.set_parallel(true)
	t.tween_property(camera, "global_transform", target_transform, 2.)
	t.chain()
	t.tween_callback(func():
		camera_tween_finished.emit()
	)

#func _physics_process(_delta: float) -> void:
	#if camera.get_global_transform_interpolated()\
		#.is_equal_approx(target_transform): return
	
