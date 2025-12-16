extends OSDialog
class_name OSAcceptDialog

var dialog_text: String = ""
var ok_button_text: String = "OK"

var message_label: Label
var ok_button: Button

static func create(text: String = "", ok_text: String = "OK") -> OSAcceptDialog:
	var dialog = OSAcceptDialog.new()
	dialog.dialog_text = text
	dialog.ok_button_text = ok_text
	return dialog

func _ready() -> void:
	_build_dialog()
	super._ready()

func _build_dialog() -> void:
	# Create dialog content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
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
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	content_vbox.add_child(button_container)
	
	ok_button = Button.new()
	ok_button.text = ok_button_text
	ok_button.custom_minimum_size = Vector2(80, 30)
	button_container.add_child(ok_button)
	
	ok_button.pressed.connect(func(): close_dialog("ok"))
	
	# Set window properties
	custom_init(Vector2(400, 150))
