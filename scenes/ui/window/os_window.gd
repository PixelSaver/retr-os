extends PanelContainer
class_name OSWindow

@export var MIN_SIZE := Vector2(200, 150)
@export var RESIZE_BORDER_THICKNESS := 8 # Thickness of the clickable border area

enum ResizeEdge {
	NONE = 0,
	TOP = 1,
	BOTTOM = 2,
	LEFT = 4,
	RIGHT = 8,
	TOP_LEFT = TOP | LEFT,
	TOP_RIGHT = TOP | RIGHT,
	BOTTOM_LEFT = BOTTOM | LEFT,
	BOTTOM_RIGHT = BOTTOM | RIGHT
}

## Resizing state variables
var is_resizing := false
var active_resize_mode : ResizeEdge = ResizeEdge.NONE  # The mode being used for active resize
## Stores the original state when resizing started
var resize_start_rect := Rect2()

@export var button_array : Array[WindowButton]
@onready var title_bar: HBoxContainer = $VBoxContainer/TitleBar
@onready var title_label: RichTextLabel = title_bar.get_node(^"Title")

@export_group("Permanent")
@export var program_container: Control 
var is_dragging := false
## Stores the distance from the window origin to the click point
var drag_start_offset := Vector2.ZERO 
var is_minimized := false
var is_fullscreen := false
## Stores the window's position and size before it was minimized or fullscreened
var restored_rect := Rect2()

var held_program : Program 

func custom_init(rect_size:Vector2, init_pos:Vector2=Vector2.ONE*-1) -> void:
	WindowManager.all_windows.append(self)
	var new_size = rect_size 
	if new_size.x < MIN_SIZE.x:
		new_size.x = MIN_SIZE.x
	if new_size.y < MIN_SIZE.y:
		new_size.y = MIN_SIZE.y
	
	# Set the size
	size = new_size
	
	# Set position (center if not specified)
	if init_pos == Vector2.ONE*-1:
		self.position = get_parent_control().get_rect().size/2 - new_size/2
	else:
		self.position = init_pos

func load_program(prog: Program) -> void:
	if held_program:
		push_warning("OSWindow already has a program loaded. Call unload_program() first.")
		return
	
	held_program = prog
	
	program_container.add_child(prog)
	prog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Wait for program to be ready if needed
	if not held_program.is_node_ready():
		await held_program.ready
	
	_update_window_title(held_program.title)
	
	#if held_program.icon:
		#_update_window_icon(held_program.icon)
	
	_connect_program_signals()
	
	held_program.start_program()

## Unload the current program (cleanup)
func unload_program() -> void:
	if held_program:
		held_program.end_program()
		program_container.remove_child(held_program)
		held_program.queue_free()
		held_program = null

## Update the window title
func _update_window_title(new_title: String) -> void:
	if title_label:
		title_label.text = new_title

## Update the window icon (if you have one in title bar)
## TODO Implement icons in the title bar
func _update_window_icon(icon: Texture2D) -> void:
	var title_icon = title_bar.get_node_or_null("TitleIcon")
	if title_icon and title_icon is TextureRect:
		title_icon.texture = icon

## Connect to program signals
func _connect_program_signals() -> void:
	if held_program.has_signal("title_changed"):
		held_program.title_changed.connect(_update_window_title)
	
	if held_program.has_signal("request_close"):
		held_program.request_close.connect(_close_window)
	
	if held_program.has_signal("request_minimize"):
		held_program.request_minimize.connect(toggle_minimize)
	
	if held_program.has_signal("request_fullscreen"):
		held_program.request_fullscreen.connect(toggle_fullscreen)
	
	if held_program.has_signal("close_window"):
		held_program.close_window.connect(_close_window)

## Handle window button presses
func _on_window_button_pressed(but: WindowButton) -> void:
	match but.name.to_lower():
		"minimize":
			toggle_minimize()
		"fullscreen":
			toggle_fullscreen()
		"close":
			_close_window()
		_:
			pass

func _close_window() -> void:
	if held_program:
		held_program.end_program()
		
		# If program has unsaved changes, it could cancel the close
		if held_program.has_method("can_close"):
			if not held_program.can_close():
				return # Don't close
	
	# Remove from window manager
	if WindowManager and WindowManager.all_windows:
		WindowManager.all_windows.erase(self)
	
	hide()
	queue_free()

func _ready() -> void:
	if title_bar:
		title_bar.gui_input.connect(_on_title_bar_gui_input)
		title_bar.mouse_entered.connect(_on_title_bar_hover)
		title_bar.mouse_exited.connect(_on_title_bar_unhover)
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
		# 1. Update the position based on the drag
		var new_global_position = get_global_mouse_position() - drag_start_offset

		# Get the parent's boundaries (assuming the parent is the container)
		var parent_size = get_parent().size
		var window_size = size

		# 2. Calculate margins
		var margins = [
			4, # min x
			3, # min y
			4, # max x
			2, # max y
		]
		var min_x = margins[0]
		var min_y = margins[1]
		
		# 3. Clamp the new position within the bounds
		new_global_position.x = clamp(new_global_position.x, min_x, parent_size.x - window_size.x - margins[2])
		new_global_position.y = clamp(new_global_position.y, min_y, parent_size.y - window_size.y - margins[3])
		
		# 4. Apply the clamped position
		global_position = new_global_position
	elif is_resizing:
		_handle_resizing()
		_update_cursor_shape(active_resize_mode)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_resizing and not is_dragging:
		var hover_mode := _get_resize_mode(get_local_mouse_position())
		_update_cursor_shape(hover_mode)
	
	# Bring to front when the window is clicked (not just the title bar)
	if event.is_action_pressed("l_click") and not is_minimized:
		bring_to_front()
		
		# Determine if we are on a resize border when the click happens
		var current_resize_mode = _get_resize_mode(get_local_mouse_position())

		if current_resize_mode != ResizeEdge.NONE and not is_fullscreen:
			is_resizing = true
			is_dragging = false # Ensure drag is off
			active_resize_mode = current_resize_mode # Store the active resize mode
			resize_start_rect = Rect2(global_position, size)
			drag_start_offset = get_global_mouse_position()
			get_viewport().set_input_as_handled()
			return # Handled by resize, skip other clicks

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
		size = viewport_size / self.scale
		
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

## Determines which edge or corner the mouse is currently over
func _get_resize_mode(local_mouse_pos: Vector2) -> ResizeEdge:
	# Don't detect new resize modes when already in these states
	if is_fullscreen or is_minimized or is_resizing or is_dragging:
		return ResizeEdge.NONE
	
	var mode = ResizeEdge.NONE
	var thickness = RESIZE_BORDER_THICKNESS
	var local_rect = Rect2(Vector2.ZERO, size)

	# Check vertical edges
	if local_mouse_pos.y < thickness:
		mode |= ResizeEdge.TOP
	elif local_mouse_pos.y > local_rect.size.y - thickness:
		mode |= ResizeEdge.BOTTOM

	# Check horizontal edges
	if local_mouse_pos.x < thickness:
		mode |= ResizeEdge.LEFT
	elif local_mouse_pos.x > local_rect.size.x - thickness:
		mode |= ResizeEdge.RIGHT
		
	# Don't allow resizing if clearly over the non-top part of the title bar
	# Use a slightly smaller buffer for this check
	if mode != ResizeEdge.NONE and local_mouse_pos.y < title_bar.size.y - (thickness / 2.0) and not (mode & ResizeEdge.TOP):
		return ResizeEdge.NONE
	
	return mode

## Changes the mouse cursor icon based on resize mode
func _update_cursor_shape(mode: ResizeEdge) -> void:
	var shape = Control.CURSOR_ARROW
	
	match mode:
		ResizeEdge.TOP, ResizeEdge.BOTTOM:
			shape = Control.CURSOR_VSIZE
		ResizeEdge.LEFT, ResizeEdge.RIGHT:
			shape = Control.CURSOR_HSIZE
		ResizeEdge.TOP_LEFT, ResizeEdge.BOTTOM_RIGHT:
			shape = Control.CURSOR_FDIAGSIZE # Forward diagonal (NW-SE)
		ResizeEdge.TOP_RIGHT, ResizeEdge.BOTTOM_LEFT:
			shape = Control.CURSOR_BDIAGSIZE # Backward diagonal (NE-SW)
		_:
			shape = Control.CURSOR_ARROW
			
	mouse_default_cursor_shape = shape

## Main logic for updating window rect during a resize drag
func _handle_resizing() -> void:
	var mouse_pos = get_global_mouse_position()
	var delta = mouse_pos - drag_start_offset
	var new_pos = resize_start_rect.position
	var new_size = resize_start_rect.size

	# Handle Horizontal Resizing
	if active_resize_mode & ResizeEdge.LEFT:
		var new_x = resize_start_rect.position.x + delta.x
		var new_w = resize_start_rect.size.x - delta.x
		if new_w >= MIN_SIZE.x:
			new_pos.x = new_x
			new_size.x = new_w
		else: # Hit min size, snap position/size
			new_pos.x = resize_start_rect.position.x + (resize_start_rect.size.x - MIN_SIZE.x)
			new_size.x = MIN_SIZE.x
	elif active_resize_mode & ResizeEdge.RIGHT:
		new_size.x = max(MIN_SIZE.x, resize_start_rect.size.x + delta.x)

	# Handle Vertical Resizing
	if active_resize_mode & ResizeEdge.TOP:
		var new_y = resize_start_rect.position.y + delta.y
		var new_h = resize_start_rect.size.y - delta.y
		if new_h >= MIN_SIZE.y:
			new_pos.y = new_y
			new_size.y = new_h
		else: # Hit min size, snap position/size
			new_pos.y = resize_start_rect.position.y + (resize_start_rect.size.y - MIN_SIZE.y)
			new_size.y = MIN_SIZE.y
	elif active_resize_mode & ResizeEdge.BOTTOM:
		new_size.y = max(MIN_SIZE.y, resize_start_rect.size.y + delta.y)

	# Apply changes
	global_position = new_pos
	size = new_size

func _input(event: InputEvent) -> void:
	# Check for the actual left mouse button release event
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging:
			is_dragging = false
			restored_rect = Rect2(global_position, size)
			get_viewport().set_input_as_handled()
			
		if is_resizing: # Separate check for resizing
			is_resizing = false
			active_resize_mode = ResizeEdge.NONE
			# Update cursor shape after resize ends
			var current_mode = _get_resize_mode(get_local_mouse_position())
			_update_cursor_shape(current_mode) 
			restored_rect = Rect2(global_position, size)
			get_viewport().set_input_as_handled()
			return

func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("l_click"):
		bring_to_front()
	
	# Start dragging only if not fullscreen, minimized, AND not starting a resize
	if event.is_action_pressed("l_click") and not is_fullscreen and not is_minimized and not is_resizing:
		drag_start_offset = get_global_mouse_position() - global_position
		is_dragging = true
		get_viewport().set_input_as_handled()

func _on_title_bar_hover():
	if not is_resizing and not is_dragging:
		title_bar.mouse_default_cursor_shape = Control.CURSOR_DRAG

func _on_title_bar_unhover():
	if not is_resizing and not is_dragging:
		title_bar.mouse_default_cursor_shape = Control.CURSOR_ARROW
