extends VBoxContainer
class_name OSMenuPopup

# Emitted when an item in the popup menu is pressed, along with the item's ID.
signal id_pressed(id: int)
# Emitted when the user clicks outside, indicating the menu should close.
signal closed

var is_closing := false

func _init():
	# Add styling to make it look like a floating menu/popup (PanelContainer style)
	add_theme_stylebox_override("panel", StyleBoxFlat.new())
	var style = get_theme_stylebox("panel") as StyleBoxFlat
	style.bg_color = Color(0.15, 0.15, 0.15)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	
	# Ensure the popup can expand to fit its content
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Must be set to allow input processing outside of its boundaries
	set_process_unhandled_input(true) 
	
	# Set to top level so its position is global/screen-relative
	#set_as_top_level(true)
	visible = false

# Custom handler for button presses inside the menu
func on_item_pressed(id: int) -> void:
	id_pressed.emit(id)
	is_closing = true # Prevent immediate close from the input handler
	closed.emit()
	is_closing = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Close if the user clicks the left mouse button anywhere outside the menu
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_closing:
			return # Already closing via button press

		var global_click_pos = get_global_mouse_position()
		var global_rect = Rect2(global_position, size)
		
		# If the click is outside our bounds, close the menu
		if not global_rect.has_point(global_click_pos):
			closed.emit()
			get_viewport().set_input_as_handled()
