extends Node

## Registry of all available programs
var programs: Dictionary = {}

func _ready() -> void:
	_register_builtin_programs()

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
	var instance = prog_data.scene.instantiate() as Program
	
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
	register_program("template", 
		preload("res://scenes/program/template.tscn"),
		{
			"title": "Template",
			"category": "Template",
			"description": "Just a template. Lorem ipsum etcetera"
		}
	)
