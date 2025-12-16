extends OSDialog
class_name OSInputDialog

signal text_submitted(text: String)

var dialog_text: String = ""
var placeholder_text: String = ""
var default_text: String = ""
var ok_button_text: String = "OK"
var cancel_button_text: String = "Cancel"

@onready var message_label: Label
@onready var input_field: LineEdit
@onready var ok_button: Button

func _init(prompt: String = "", default: String = "", placeholder: String = "") -> void:
	dialog_text = prompt
	default_text = default
	placeholder_text = placeholder

func _ready() -> void:
	super._ready()
	_build_dialog()

func _build_dialog() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	program_container.add_child(vbox)
	
	# Message
	message_label = Label.new()
	message_label.text = dialog_text
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(message_label)
	
	# Input field
	input_field = LineEdit.new()
	input_field.text = default_text
	input_field.placeholder_text = placeholder_text
	vbox.add_child(input_field)
	input_field.text_submitted.connect(_on_text_submitted)
	
	# Buttons
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.add_theme_constant_override("separation", 8)
	vbox.add_child(button_container)
	
	var cancel_btn = Button.new()
	cancel_btn.text = cancel_button_text
	cancel_btn.custom_minimum_size = Vector2(80, 0)
	button_container.add_child(cancel_btn)
	cancel_btn.pressed.connect(func(): close_dialog("cancel"))
	
	ok_button = Button.new()
	ok_button.text = ok_button_text
	ok_button.custom_minimum_size = Vector2(80, 0)
	button_container.add_child(ok_button)
	ok_button.pressed.connect(_on_ok_pressed)
	
	title_label.text = "Input"
	custom_init(Vector2(400, 150))
	
	# Focus the input field
	input_field.grab_focus()

func _on_ok_pressed() -> void:
	_on_text_submitted(input_field.text)

func _on_text_submitted(text: String) -> void:
	text_submitted.emit(text)
	close_dialog("ok")

func get_text() -> String:
	return input_field.text if input_field else ""
