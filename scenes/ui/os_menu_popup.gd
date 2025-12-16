extends Panel
class_name OSMenuPopup

var vbox: VBoxContainer 
var margin_cont: MarginContainer

# Emitted when an item in the popup menu is pressed, along with the item's ID.
signal id_pressed(id: int)
# Emitted when the user clicks outside, indicating the menu should close.
signal closed

var is_closing := false

func _init():
	var offset = 4
	margin_cont = MarginContainer.new()
	add_theme_constant_override("margin_top", offset)
	add_theme_constant_override("margin_bottom", -offset)
	add_theme_constant_override("margin_left", offset)
	add_theme_constant_override("margin_right", -offset)
	add_child(margin_cont)
	vbox = VBoxContainer.new()
	margin_cont.add_child(vbox)
	vbox.minimum_size_changed.connect(_update_size)
	
	# Ensure the popup can expand to fit its content
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Must be set to allow input processing outside of its boundaries
	set_process_unhandled_input(true) 
	
	# Set to top level so its position is global/screen-relative
	#set_as_top_level(true)
	visible = false

func _update_size():
	self.size = margin_cont.get_combined_minimum_size()
	

# Custom handler for button presses inside the menu
func on_item_pressed(id: int) -> void:
	id_pressed.emit(id)
	is_closing = true # Prevent immediate close from the input handler
	closed.emit()
	is_closing = false

func _input(event: InputEvent) -> void:
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
