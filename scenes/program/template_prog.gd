extends Program
class_name TemplateProgram

const TEMPLATE = preload("uid://da5pp54abwfdn")

func _init():
	self.program_end.connect(_on_program_end)
	self.program_start.connect(_on_program_start)
	self.program_process.connect(_on_program_process)
	self.program_scene = TEMPLATE


func _on_program_end():
	pass

func _on_program_start():
	pass

func _on_program_process(delta:float):
	pass
