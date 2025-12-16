extends Program
class_name TemplateProgram

func _ready():
	self.program_end.connect(_on_program_end)
	self.program_start.connect(_on_program_start)
	self.program_process.connect(_on_program_process)


func _on_program_end():
	pass

func _on_program_start():
	pass

func _on_program_process(delta:float):
	pass
