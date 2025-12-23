extends HBoxContainer
class_name ChangeScreen

enum Sides {
	LEFT,
	RIGHT,
}
enum Positions {
	MAC,
	RADIO,
	HOME,
}
@export var left_control : Control
@export var right_control : Control
var current_cam_pos:Positions = Positions.MAC

func _ready() -> void:
	left_control.mouse_entered.connect(_on_mouse_entered_edge.bind(Sides.LEFT))
	right_control.mouse_entered.connect(_on_mouse_entered_edge.bind(Sides.RIGHT))

func _on_mouse_entered_edge(side:Sides):
	print("Mouse entered side: %s" % str(side))
	match current_cam_pos:
		Positions.MAC:
			if side == Sides.RIGHT: 
				Global.cam_to_marker.emit("radio")
				current_cam_pos = Positions.RADIO
		Positions.RADIO:
			if side == Sides.LEFT: 
				Global.cam_to_marker.emit("mac")
				current_cam_pos = Positions.MAC
		Positions.HOME:
			pass
