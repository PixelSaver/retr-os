extends Node3D

@onready var screen: Screen = $Screen


func _input(event: InputEvent) -> void:
	screen.push_input(event)
