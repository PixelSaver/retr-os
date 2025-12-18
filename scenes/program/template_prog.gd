extends Program
class_name TemplateProgram

func _program_ready() -> void:
	pass

func _program_start(args:Array=[]) -> void:
	print("%s started" % get_class())

func _program_end() -> void:
	print("%s ended" % get_class())
