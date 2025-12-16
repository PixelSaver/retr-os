extends OSWindow
class_name OSDialog

signal confirmed()
signal canceled()
signal custom_action(action: String)

var dialog_result: String = ""
var is_modal: bool = true
var _modal_overlay: ColorRect

func _init() -> void:
	# Dialogs don't need the full window button array
	pass

func _ready() -> void:
	super._ready()
	
	if is_modal:
		_create_modal_overlay()
	
	call_deferred("_center_dialog")

func _center_dialog() -> void:
	if get_parent():
		var parent_size = get_parent().size
		global_position = (parent_size - size) / 2

func _create_modal_overlay() -> void:
	#TODO Fix overlay
	return
	if not get_parent():
		return
	
	# Create a dark overlay behind the dialog
	_modal_overlay = ColorRect.new()
	_modal_overlay.color = Color(0, 0, 0, 0.5)
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	get_parent().add_child(_modal_overlay)
	get_parent().move_child(_modal_overlay, get_index())
	
	tree_exiting.connect(_cleanup_overlay)

func _cleanup_overlay() -> void:
	if _modal_overlay and is_instance_valid(_modal_overlay):
		_modal_overlay.queue_free()

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
