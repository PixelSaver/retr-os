extends PanelContainer
class_name OSWindow

@export var button_array : Array[WindowButton]
@onready var title_bar: HBoxContainer = $VBoxContainer/TitleBar
var is_dragging := false
## Stores the distance from the window origin to the click point
var drag_start_offset := Vector2.ZERO 
var is_minimized := false
var is_fullscreen := false
## Stores the window's position and size before it was minimized or fullscreened
var restored_rect := Rect2()

func custom_init(rect_size:Vector2, init_pos:Vector2=Vector2.ONE*-1) -> void:
	size = rect_size
	if init_pos == Vector2.ONE*-1:
		self.position = get_viewport_rect().size/2 - size/2.

func _ready() -> void:
	if title_bar:
		title_bar.gui_input.connect(_on_title_bar_gui_input)
	else:
		print("Warning: OSWindow requires a child node named 'TitleBar' for dragging.")
	for button in button_array:
		button.window_button_pressed.connect(_on_window_button_pressed)
	
	# Store initial state for restoration
	restored_rect = Rect2(global_position, size)
	
	# Bring to front on load (optional, useful for initial scene setup)
	call_deferred("bring_to_front")

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drag_start_offset

func _gui_input(event: InputEvent) -> void:
	# Bring to front when the window is clicked (not just the title bar)
	if event.is_action_pressed("l_click") and not is_minimized:
		bring_to_front()
func bring_to_front() -> void:
	if get_parent():
		get_parent().move_child(self, get_parent().get_child_count() - 1)

func toggle_minimize() -> void:
	is_minimized = not is_minimized
	
	if is_minimized:
		# Save current position/size before minimizing (if not already fullscreen)
		if not is_fullscreen:
			restored_rect = Rect2(global_position, size)
			
		visible = false # Hide the window
		# TODO: Implement a Taskbar icon for access
	else:
		visible = true # Restore visibility
		# If it was minimized *from* fullscreen, restore fullscreen state
		if is_fullscreen:
			_apply_fullscreen_state()
		else:
			# Otherwise, restore original position and size
			global_position = restored_rect.position
			size = restored_rect.size
		
		bring_to_front()

func _apply_fullscreen_state() -> void:
	var viewport_size = get_viewport_rect().size
	
	if is_fullscreen:
		# Save current position/size before entering fullscreen (if not minimized)
		if not is_minimized:
			restored_rect = Rect2(global_position, size)
			
		# Set to the size and position of the viewport
		global_position = Vector2.ZERO
		size = viewport_size
		
		# Disable dragging while in fullscreen
		is_dragging = false 
		
	else:
		# Restore position and size
		global_position = restored_rect.position
		size = restored_rect.size

func toggle_fullscreen() -> void:
	is_fullscreen = not is_fullscreen
	_apply_fullscreen_state()
	
	if not is_minimized:
		bring_to_front()

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
			
			title_bar.grab_focus() 
			
			get_viewport().set_input_as_handled()

func _on_window_button_pressed(but:WindowButton):
	match but.name.to_lower():
		"minimize":
			toggle_minimize()
		"fullscreen":
			toggle_fullscreen()
		"close":
			self.hide()
			self.queue_free()
		_:
			pass
