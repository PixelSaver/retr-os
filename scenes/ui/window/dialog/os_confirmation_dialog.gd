extends OSDialog
class_name OSConfirmationDialog

var dialog_text: String = ""
var ok_button_text: String = "OK"
var cancel_button_text: String = "Cancel"
var extra_buttons: Array[Dictionary] = [] # {text: String, action: String}

var message_label: Label
var button_container: HBoxContainer
const OS_CONFIRMATION_DIALOG = preload("uid://b7j3q5m6hyh5e")

static func create(text: String = "", ok_text: String = "OK", cancel_text: String = "Cancel") -> OSConfirmationDialog:
	var dialog = OS_CONFIRMATION_DIALOG.instantiate() as OSConfirmationDialog
	dialog.dialog_text = text
	dialog.ok_button_text = ok_text
	dialog.cancel_button_text = cancel_text
	return dialog

func add_button(text: String, action: String = "") -> void:
	if action.is_empty():
		action = text.to_lower()
	extra_buttons.append({"text": text, "action": action})

func _ready() -> void:
	_build_dialog()
	super._ready()

func _build_dialog() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	program_container.add_child(vbox)
	
	# Add margins
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(content_vbox)
	
	# Message
	message_label = Label.new()
	message_label.text = dialog_text
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(300, 0)
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(message_label)
	
	# Buttons
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.add_theme_constant_override("separation", 8)
	content_vbox.add_child(button_container)
	
	# Cancel button (leftmost)
	var cancel_btn = Button.new()
	cancel_btn.text = cancel_button_text
	cancel_btn.custom_minimum_size = Vector2(80, 30)
	button_container.add_child(cancel_btn)
	cancel_btn.pressed.connect(func(): close_dialog("cancel"))
	
	# Add extra buttons
	for btn_data in extra_buttons:
		_add_button_to_container(btn_data.text, btn_data.action)
	
	# OK button (rightmost)
	var ok_btn = Button.new()
	ok_btn.text = ok_button_text
	ok_btn.custom_minimum_size = Vector2(80, 30)
	button_container.add_child(ok_btn)
	ok_btn.pressed.connect(func(): close_dialog("ok"))
	
	# Set window properties
	custom_init(Vector2(400, 150))

func _add_button_to_container(text: String, action: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 30)
	button_container.add_child(btn)
	btn.pressed.connect(func(): close_dialog(action))
	# Move before OK button
	button_container.move_child(btn, button_container.get_child_count() - 2)
