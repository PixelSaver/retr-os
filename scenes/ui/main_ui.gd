extends CanvasLayer
class_name MainUI

var par : SubViewport
@export var main_menu : Control
@export var computer_ui : Control
@onready var theme: Control = $Theme
@onready var window_container: Control = $Theme/GUI/ProgramContainer
@onready var gui = $Theme/GUI
@onready var controlsDialog = preload ("res://assets/Themes/TestDialog.tscn")
@onready var os_window_scene = preload("res://scenes/ui/window/os_window.tscn")
var program_list : Array[Program] = []

func _ready():
	Global.main_ui = self
	par = get_parent() as SubViewport

func _on_Button_button_pressed() -> void:
	var inst := os_window_scene.instantiate() as OSWindow
	add_child(inst)
	inst.load_program(TemplateProgram.new())
	inst.custom_init(Vector2(100,100))

func _on_alert_pressed() -> void:
	pass


func _on_confirm_pressed() -> void:
	pass


func _on_file_pressed() -> void:
	var dialog = FileDialog.new()
	dialog.title = "Save a file"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.size = Vector2i(720, 450)
	dialog.dialog_hide_on_ok = true
	dialog.dialog_close_on_escape = true
	dialog.visible = true
	gui.add_child(dialog)
	
func put_on_top(control):
	var parent = control.get_parent()
	parent.move_child(control, parent.get_child_count())

func load_program(prog:Program):
	prog.load_program_scene()
	window_container.add_child(prog)
	program_list.append(prog)
	
