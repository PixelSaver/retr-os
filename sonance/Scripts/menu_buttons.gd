extends Node3D
class_name MenuButtons

@export var play_but : RadioMenuButton
var button_hovered = null

func _ready() -> void:
	#play_but.connect("pressed", _on_play_pressed)
	pass
	
func _on_play_pressed():
	var world = Global.world_root
	if not world: 
		push_error("world is null, %s" % world)
		return
	await get_tree().create_timer(0.3).timeout
	world.main_to_radio()
#func _on_settings_pressed():
	#pass
#func _on_quit_pressed():
	#pass
