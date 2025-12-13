extends CanvasLayer
class_name MainUI

var par : SubViewport
@export var main_menu : Control
@export var computer_ui : Control
@onready var theme: Control = $Theme
@onready var gui = $Theme/GUI
@onready var controlsDialog = preload ("res://assets/Themes/TestDialog.tscn")


func _ready():
	Global.main_ui = self
	par = get_parent() as SubViewport

func _on_Button_button_pressed() -> void:
	var window = Window.new()
	window.title = "Controls Demo"	
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	window.visible = true
	window.size.x = 595
	window.size.y = 380	
	window.close_requested.connect(window.queue_free)
	window.add_child(controlsDialog.instantiate())
	
	gui.add_child(window)


func _on_alert_pressed() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Alert"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.size = Vector2i(200, 100)
	dialog.dialog_hide_on_ok = true
	dialog.dialog_close_on_escape = true
	dialog.dialog_text = "Hello World"
	dialog.visible = true
	gui.add_child(dialog)


func _on_confirm_pressed() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Please confirm"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.size = Vector2i(200, 100)
	dialog.dialog_hide_on_ok = true
	dialog.dialog_close_on_escape = true
	dialog.dialog_text = "This is a dialog. Ok?"
	dialog.visible = true
	gui.add_child(dialog)


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
