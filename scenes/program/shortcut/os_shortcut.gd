extends Control
class_name OSShortcut

@export_enum(
	" ",
	"TemplateProgram",
)
var program_type : String

func get_program():
	var out = ProgramManager.PROGRAM_CLASSES.get(program_type)
	if out:
		return out
	else:
		return TemplateProgram

func _ready() -> void:
	Global.main_ui
