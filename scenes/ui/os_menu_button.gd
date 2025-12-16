extends Button
class_name OSMenuButton

## Emitted when an item in the popup menu is pressed, along with the item's ID.
signal id_pressed(id: int)

# The list of items to display in the menu
var items: Array[Dictionary] = []

# Internal reference to the generated popup
var popup_menu: OSMenuPopup

func _ready() -> void:
	# Connect the base button's press signal to our logic
	self.pressed.connect(_on_menu_button_pressed)

# --- Public API (mimics MenuButton/PopupMenu) ---

func get_popup() -> OSMenuButton:
	# Ensure the popup structure exists and is added to the scene root
	if not is_instance_valid(popup_menu):
		popup_menu = OSMenuPopup.new()
		# Add the popup to the root of the scene tree to ensure it floats above all controls
		add_child(popup_menu)
		
		# Connect the popup's signals to our button's signals
		popup_menu.id_pressed.connect(func(id):
			id_pressed.emit(id)
			_close_popup()
		)
		popup_menu.closed.connect(_close_popup)
		
	return self # Return self to allow chaining API calls like .add_item()

func clear() -> void:
	items.clear()
	if is_instance_valid(popup_menu):
		_rebuild_popup()

func add_item(label: String, id: int = -1, shortcut: Shortcut = null) -> void:
	var item_id = id if id != -1 else items.size()
	items.append({
		"label": label,
		"id": item_id,
		"shortcut": shortcut,
		"is_separator": false
	})
	if is_instance_valid(popup_menu):
		_rebuild_popup()

func add_separator() -> void:
	items.append({"is_separator": true})
	if is_instance_valid(popup_menu):
		_rebuild_popup()

func set_item_shortcut(id: int, shortcut: Shortcut) -> void:
	for i in range(items.size()):
		if not items[i].is_separator and items[i].id == id:
			items[i].shortcut = shortcut
			# Since we store the shortcut, we should rebuild the UI to display it
			if is_instance_valid(popup_menu):
				_rebuild_popup()
			return

# --- Internal Logic ---

func _rebuild_popup() -> void:
	if not is_instance_valid(popup_menu):
		return
		
	# Clear existing items
	for child in popup_menu.get_children():
		child.queue_free()
	
	popup_menu.z_index = 1
	
	# Populate with new items
	for item in items:
		if item.is_separator:
			var separator = HSeparator.new()
			popup_menu.add_child(separator)
			continue
			
		
		var button = Button.new()
		#button.text = item.label
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(100, 24) 
		button.set_meta("item_id", item.id)
		button.pressed.connect(func(): popup_menu.on_item_pressed(item.id))
		
		var item_hbox = HBoxContainer.new()
		item_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		item_hbox.modulate = Color.BLACK
		item_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		button.add_child(item_hbox)
		
		var item_name = Label.new()
		item_name.text = item.label
		item_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_name.focus_mode = Control.FOCUS_NONE
		
		item_hbox.add_child(item_name)
		
		if item.shortcut:
			var shortcut_label = Label.new()
			
			var shortcut_text = ""
			for _event in item.shortcut.events:
				var event = _event as InputEventKey
				shortcut_text += OS.get_keycode_string(event.get_keycode_with_modifiers())
			
			shortcut_label.text = shortcut_text
			shortcut_label.size_flags_horizontal = Control.SIZE_SHRINK_END
			shortcut_label.add_theme_constant_override("separation", 16)
			shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shortcut_label.focus_mode = Control.FOCUS_NONE
			#shortcut_label.scroll_active = false
			
			item_hbox.add_child(shortcut_label)

		popup_menu.add_child(button)

func _on_menu_button_pressed() -> void:
	if not is_instance_valid(popup_menu):
		get_popup() # Initialize the popup
		_rebuild_popup()
		
	# Position the popup below the button
	var button_size = size
	
	popup_menu.position = button_size
	
	# Set the popup to appear immediately (important for modal behavior)
	popup_menu.visible = true
	popup_menu.set_focus_mode(Control.FOCUS_ALL)
	popup_menu.grab_focus()

func _close_popup() -> void:
	if is_instance_valid(popup_menu):
		popup_menu.visible = false
		get_viewport().set_input_as_handled()
