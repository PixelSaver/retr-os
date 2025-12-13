extends CanvasLayer
class_name MainUI

var par : SubViewport
@export var main_menu : Control
@export var computer_ui : Control
@onready var theme: Control = $Theme
@onready var gui = $Theme/GUI
@onready var controlsDialog = preload ("res://assets/Themes/TestDialog.tscn")
@onready var os_window_scene = preload("res://scenes/ui/window/os_window.tscn")

func _ready():
	Global.main_ui = self
	par = get_parent() as SubViewport

func _on_Button_button_pressed() -> void:
	var inst := os_window_scene.instantiate() as OSWindow
	add_child(inst)
	inst.custom_init(Vector2(100,100))


func _on_alert_pressed() -> void:
	pass


func _on_confirm_pressed() -> void:
	pass


func _on_file_pressed() -> void:
	pass
	
func put_on_top(control):
	var parent = control.get_parent()
	parent.move_child(control, parent.get_child_count())
