extends OSDialog
class_name OSConfirmationDialog

var dialog_text: String = ""
var ok_button_text: String = "OK"
var cancel_button_text: String = "Cancel"
var extra_buttons: Array[String] = []

@onready var message_label: Label
@onready var button_container: HBoxContainer

func _init(text: String = "", ok_text: String = "OK", cancel_text: String = "Cancel") -> void:
	dialog_text = text
	ok_button_text = ok_text
	cancel_button_text = cancel_text

func _ready() -> void:
	super._ready()
	_build_dialog()

func add_button(text: String, action: String = "") -> void:
	if action.is_empty():
		action = text.to_lower()
	extra_buttons.append(action)
	
	if button_container:
		_add_button_to_container(text, action)

func _build_dialog() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	program_container.add_child(vbox)
	
	# Message
	message_label = Label.new()
	message_label.text = dialog_text
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(300, 0)
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(message_label)
	
	# Buttons
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.add_theme_constant_override("separation", 8)
	vbox.add_child(button_container)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = cancel_button_text
	cancel_btn.custom_minimum_size = Vector2(80, 0)
	button_container.add_child(cancel_btn)
	cancel_btn.pressed.connect(func(): close_dialog("cancel"))
	
	# Add extra buttons
	for i in extra_buttons.size():
		_add_button_to_container(extra_buttons[i], extra_buttons[i])
	
	# OK button
	var ok_btn = Button.new()
	ok_btn.text = ok_button_text
	ok_btn.custom_minimum_size = Vector2(80, 0)
	button_container.add_child(ok_btn)
	ok_btn.pressed.connect(func(): close_dialog("ok"))
	
	# Set window properties
	title_label.text = "Confirm"
	custom_init(Vector2(400, 150))

func _add_button_to_container(text: String, action: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 0)
	button_container.add_child(btn)
	btn.pressed.connect(func(): close_dialog(action))
	# Move before OK button
	button_container.move_child(btn, button_container.get_child_count() - 2)
