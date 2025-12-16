extends OSWindow
class_name OSDialog

signal confirmed()
signal canceled()
signal custom_action(action: String)

var dialog_result: String = ""
var is_modal: bool = true

func _ready() -> void:
	super._ready()
	
	if is_modal:
		_create_modal_overlay()

func _create_modal_overlay() -> void:
	# Create a dark overlay behind the dialog
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Block clicks
	overlay.z_index = -1
	add_sibling(overlay)
	
	# Remove overlay when dialog closes
	tree_exiting.connect(overlay.queue_free)

func close_dialog(result: String = "") -> void:
	dialog_result = result
	match result:
		"ok", "yes", "confirm":
			confirmed.emit()
		"cancel", "no":
			canceled.emit()
		_:
			custom_action.emit(result)
	
	queue_free()
