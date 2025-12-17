extends Node3D
class_name WorldRoot

@export var anim_player : AnimationPlayer

func _ready() -> void:
	Global.world_root = self
	anim_player.play("camera_start_2", -1, 0.)
	
	if OS.is_debug_build():
		#main_to_radio()
		pass
	

func main_to_radio():
	if Global.state != Global.States.MENU: return
	Global.state = Global.States.RADIO
	anim_player.play("camera_start_2")
