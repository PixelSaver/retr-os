extends MeshInstance3D
class_name Radio

@export var knob1 : Area3D
@export var knob2 : Area3D
@export var sensitivity : float = 0.1
@export var tuning_fork : StaticBody3D
@export var outline_component : OutlineComponent
@export var audio_man : AudioManager
var tuning_fork_target : float = -.08
var tuning : float = 0.
var volume : float = 0.
var knob_hovered : Area3D
var clicked = false
var dragging = false

func _ready():
	knob1.connect("mouse_entered", _on_knob_1)
	knob2.connect("mouse_entered", _on_knob_2)
	knob1.connect("mouse_exited", _on_knob_exit)
	knob2.connect("mouse_exited", _on_knob_exit)
	
func _on_knob_1():
	if dragging: return
	outline_component.outline_parent(true,\
			knob1.get_node("KnobModel"))
	knob_hovered = knob1
func _on_knob_2():
	if dragging: return
	outline_component.outline_parent(true,\
			knob2.get_node("KnobModel"))
	knob_hovered = knob2
func _on_knob_exit():
	outline_component.outline_parent(false,\
			knob1.get_node("KnobModel"))
	outline_component.outline_parent(false,\
			knob2.get_node("KnobModel"))
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_action("l_click"):
			clicked = event.pressed
			if clicked:
				pass
			else:
				dragging = false

	if event is InputEventMouseMotion:
		if clicked and knob_hovered:
			dragging = true
		update_knob_turn(event as InputEventMouseMotion)
	
func _process(delta: float) -> void:
	tuning_fork.position.x = lerp(tuning_fork.position.x, tuning_fork_target, delta*10)
	print(tuning_fork.position)

func update_knob_turn(event:InputEventMouseMotion):
	if not dragging: return
	match knob_hovered:
		null:
			return
		knob2:
			update_tuning(event.relative)
		knob1:
			volume = clampf(volume + (event.relative.x - event.relative.y) * sensitivity, -30., 50.)
			knob1.rotation.z = volume * -0.05
			audio_man.set_frequency(get_freq(), (volume+50.) / 50.)
	
func update_tuning(event_rel:Vector2):
	tuning = clampf(tuning+(event_rel.x - event_rel.y) * sensitivity, 0., 50.)
	knob2.rotation.z = tuning * -0.05
	tuning_fork_target = lerp(-.08, .185, tuning/50.)
	audio_man.set_frequency(get_freq(), (volume+50.) / 50.)

func get_freq() -> float:
	var freq = ease(tuning/50., 2.0)
	freq = lerp(50., 160., freq)
	return freq
