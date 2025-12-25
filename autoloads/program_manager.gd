extends Node

## Registry of all available programs
## Scene, title, icon, description, category
var programs: Dictionary = {}
var running_programs : Array[Program] = []
signal running_programs_list_changed

func _ready() -> void:
	_register_builtin_programs()

func add_running_program(program: Program) -> void:
	running_programs.append(program)
	running_programs_list_changed.emit()

func remove_running_program(program: Program) -> void:
	running_programs.erase(program)
	running_programs_list_changed.emit()

## Register a program type with metadata
func register_program(id: String, scene: PackedScene, metadata: Dictionary = {}) -> void:
	programs[id] = {
		"scene": scene,
		"title": metadata.get("title", id),
		"icon": metadata.get("icon", null),
		"description": metadata.get("description", ""),
		"category": metadata.get("category", "Other")
	}

## Create a new instance of a program by ID
func create_program(id: String) -> Program:
	if not programs.has(id):
		push_error("Program not found: " + id)
		return null
	
	var prog_data = programs[id]
	if prog_data.scene == null: return 
	var instance = prog_data.scene.instantiate() as Program
	instance.title = prog_data.title
	
	if not instance:
		push_error("Failed to instantiate program: " + id)
		return null
	
	return instance

## Get list of all registered program IDs
func get_program_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(programs.keys())
	return ids

## Get program metadata
func get_program_info(id: String) -> Dictionary:
	return programs.get(id, {})

## Register all built-in programs
func _register_builtin_programs() -> void:
	register_program("empty", 
		null,
		{
			"title": "",
			"icon": "",
			"category": "Empty",
			"description": "Nothing here!"
		}
	)
	register_program("template", 
		preload("res://scenes/program/template.tscn"),
		{
			"title": "Template",
			"icon": "res://assets/win98_icons/png/accesibility_window_abc.png",
			"category": "Template",
			"description": "Just a template. Lorem ipsum etcetera"
		}
	)
	register_program("text_editor", 
		preload("res://scenes/program/text_editor_program.tscn"),
		{
			"title": "Text Editor",
			"icon": "res://assets/win98_icons/png/document-0.png",
			"category": "Utilities",
			"description": "A text editor for almost nothing!"
		}
	)
	register_program("file_explorer", 
		preload("res://scenes/program/file_explorer_program.tscn"),
		{
			"title": "Pixel Files",
			"icon": "res://assets/win98_icons/png/directory_open_cool-3.png",
			"category": "Utilities",
			"description": "Get exploring!"
		}
	)
	register_program("calculator", 
		preload("res://scenes/program/calculator_program.tscn"),
		{
			"title": "Calculator",
			"icon": "res://assets/win98_icons/png/calculator-0.png",
			"category": "Utilities",
			"description": "Can calculate pretty much nothing"
		}
	)
	register_program("program_manager", 
		preload("res://scenes/program/program_manager_program.tscn"),
		{
			"title": "Program Manager",
			"icon": "res://assets/win98_icons/png/program_manager-1.png",
			"category": "Utilities",
			"description": "KILL THEM ALL"
		}
	)
	register_program("help", 
		preload("res://scenes/program/text_editor_program.tscn"),
		{
			"title": "Help",
			"icon": "res://assets/win98_icons/png/help_question_mark-0.png",
			"category": "Utilities",
			"description": "Need help?"
		}
	)
	if OS.has_feature("web"): return
	#register_program("browser", 
		#load("res://scenes/program/browser_program.tscn"),
		#{
			#"title": "Pixel Browser",
			#"icon": "res://assets/win98_icons/png/world-2.png",
			#"category": "Utilities",
			#"description": "Big files to load this"
		#}
	#)
	#register_program("website", 
		#load("res://scenes/program/browser_program.tscn"),
		#{
			#"title": "Pixel Browser",
			#"icon": "res://assets/win98_icons/png/web_file-3.png",
			#"category": "Utilities",
			#"description": "Hopefully passes arguments correctly"
		#}
	#)

#"res://assets/win98_icons/png/console_prompt-0.png"
#"res://assets/win98_icons/png/directory_closed-3.png"
#
#
#"res://assets/win98_icons/png/recycle_bin_empty_cool-5.png"
#"res://assets/win98_icons/png/recycle_bin_full_cool-5.png"
#"res://assets/win98_icons/png/amplify.png"
#"res://assets/win98_icons/png/cassette_tape-1.png"
#"res://assets/win98_icons/png/certificate-0.png"
#"res://assets/win98_icons/png/certificate_excl-1.png"
#"res://assets/win98_icons/png/envelope_closed-0.png"
#"res://assets/win98_icons/png/envelope_open_sheet-0.png"
#
#"res://assets/win98_icons/png/loudspeaker_rays-0.png"
#"res://assets/win98_icons/png/loudspeaker_muted-0.png"
#"res://assets/win98_icons/png/notepad-1.png"
#"res://assets/win98_icons/png/search_web-0.png"
#"res://assets/win98_icons/png/spider-0.png"
# "res://assets/win98_icons/png/web_file-3.png"
# "res://assets/win98_icons/png/wia_img_check-0.png"
