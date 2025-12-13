extends PanelContainer
class_name OSWindow

@export var button_array : Array[WindowButton]
@onready var title_bar: HBoxContainer = $VBoxContainer/TitleBar
var is_dragging := false
## Stores the distance from the window origin to the click point
var drag_start_offset := Vector2.ZERO 

# --- Initialization ---
func _ready() -> void:
	if title_bar:
		title_bar.gui_input.connect(_on_title_bar_gui_input)
	else:
		print("Warning: OSWindow requires a child node named 'TitleBar' for dragging.")
	for button in button_array:
		button.window_button_pressed.connect(_on_window_button_pressed)

func _process(_delta: float) -> void:
	if is_dragging:
		print("Dragging@!!")
		global_position = get_global_mouse_position() - drag_start_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		event.relative += self.position
	# Stop dragging only when the primary button is released
	if event.is_action_released("l_click"):
		if is_dragging:
			is_dragging = false
			get_viewport().set_input_as_handled()

func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("l_click"):
		# Simple inside bounds check
		if event.is_pressed(): 
			drag_start_offset = get_global_mouse_position() - global_position
			
			is_dragging = true
			
			# title_bar.grab_focus() 
			
			get_viewport().set_input_as_handled()

func _on_window_button_pressed(but:WindowButton):
	match but.name.to_lower():
		"minimize":
			pass
		"fullscreen":
			pass
		"close":
			pass
		_:
			pass
