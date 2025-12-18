extends Program
class_name OSCalculatorProgram

@onready var display_label: RichTextLabel = $VBoxContainer/Display
@onready var buttons_grid: GridContainer = $VBoxContainer/ButtonsGrid

# --- Calculator State ---
var current_value: float = 0.0
var new_number_str: String = "0"
var pending_operation: String = ""
var should_clear_display: bool = true

enum Operator { DIVIDE = 10, MULTIPLY = 11, SUBTRACT = 12, ADD = 13, EQUALS = 14 }

# Button layout map: [Display Text, ID/Action, Color (Optional)]
const BUTTON_MAP = [
	["AC", "clear", Color("#FF6666")], ["±", "negate", null], ["%", "percent", null], ["/", "divide", Color("#FF9933")],
	["7", "7", null], ["8", "8", null], ["9", "9", null], ["x", "multiply", Color("#FF9933")],
	["4", "4", null], ["5", "5", null], ["6", "6", null], ["-", "subtract", Color("#FF9933")],
	["1", "1", null], ["2", "2", null], ["3", "3", null], ["+", "add", Color("#FF9933")],
	["0", "0", null], [".", "dot", null], ["=", "equals", Color("#4CAF50")]
]


func _program_ready() -> void:
	_setup_ui()
	_build_buttons()
	_update_display()
	
	# Grab focus to enable keyboard input
	grab_focus()

func _setup_ui() -> void:
	# Configure the display label
	display_label.text = "0"
	display_label.set("custom_minimum_size", Vector2(0, 10))

func _build_buttons() -> void:
	buttons_grid.columns = 4
	
	for button_data in BUTTON_MAP:
		var btn = Button.new()
		btn.text = button_data[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.set("custom_minimum_size", Vector2(10, 10))
		
		# Apply custom color if specified (e.g., for AC or operator buttons)
		if button_data[2]:
			btn.modulate = button_data[2]
			
		# Set the action ID as metadata
		btn.set_meta("action", button_data[1])
		
		btn.pressed.connect(func(): _on_button_pressed(button_data[1]))
		
		buttons_grid.add_child(btn)

		# Handle the large "0" button if using a standard calculator layout
		if button_data[0] == "0":
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buttons_grid.add_child(Control.new()) # Add an empty placeholder to skip a column

func _update_display() -> void:
	display_label.text = new_number_str

# --- Core Logic ---

func _on_button_pressed(action: String) -> void:
	var is_digit = action.is_valid_int()
	
	if is_digit or action == "dot":
		_handle_digit_or_dot(action)
	elif action == "clear":
		_handle_clear()
	elif action == "negate" or action == "percent":
		_handle_unary_operation(action)
	elif action == "divide" or action == "multiply" or action == "subtract" or action == "add":
		_handle_binary_operation(action)
	elif action == "equals":
		_handle_equals()

func _handle_digit_or_dot(action: String) -> void:
	if should_clear_display:
		new_number_str = "0"
		should_clear_display = false
		
	if action == "dot":
		if not new_number_str.contains("."):
			new_number_str += "."
	elif new_number_str == "0":
		new_number_str = action
	else:
		new_number_str += action
		
	_update_display()

func _handle_clear() -> void:
	current_value = 0.0
	new_number_str = "0"
	pending_operation = ""
	should_clear_display = true
	_update_display()

func _handle_unary_operation(action: String) -> void:
	var val = float(new_number_str)
	
	match action:
		"negate":
			val = -val
		"percent":
			val /= 100.0
			
	# Update the string representation to reflect the result
	new_number_str = "%s" % [current_value]
	_update_display()

func _handle_binary_operation(op: String) -> void:
	if not pending_operation.is_empty():
		# Execute the previous operation before setting the new one
		_calculate_result()
	
	current_value = float(new_number_str)
	pending_operation = op
	should_clear_display = true

func _handle_equals() -> void:
	_calculate_result()
	pending_operation = ""
	should_clear_display = true

func _calculate_result() -> void:
	if pending_operation.is_empty():
		return
		
	var incoming_value = float(new_number_str)
	var result: float = current_value
	
	match pending_operation:
		"add":
			result += incoming_value
		"subtract":
			result -= incoming_value
		"multiply":
			result *= incoming_value
		"divide":
			if incoming_value != 0.0:
				result /= incoming_value
			else:
				new_number_str = "Error"
				current_value = 0.0
				pending_operation = ""
				_update_display()
				return
	
	current_value = result
	new_number_str = "%s" % [current_value]
	_update_display()

# --- Program Lifecycle ---
# Not strictly necessary for a simple calculator, but kept for structure

func _program_start(args:Array=[]) -> void:
	print("Calculator started")

func _program_end() -> void:
	print("Calculator ended")
