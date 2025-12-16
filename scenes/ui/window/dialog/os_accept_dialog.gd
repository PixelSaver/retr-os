extends OSDialog
class_name OSAcceptDialog

var dialog_text: String = ""
var ok_button_text: String = "OK"

@onready var message_label: Label
@onready var ok_button: Button

func _init(text: String = "", ok_text: String = "OK") -> void:
	dialog_text = text
	ok_button_text = ok_text

func _ready() -> void:
	super._ready()
	_build_dialog()

func _build_dialog() -> void:
	# Create dialog content
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
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(button_container)
	
	ok_button = Button.new()
	ok_button.text = ok_button_text
	ok_button.custom_minimum_size = Vector2(80, 0)
	button_container.add_child(ok_button)
	
	ok_button.pressed.connect(func(): close_dialog("ok"))
	
	# Set window properties
	title_label.text = "Message"
	custom_init(Vector2(400, 150))
