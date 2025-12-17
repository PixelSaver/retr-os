extends Node
class_name OutlineComponent

@export var outline_shader_mat : ShaderMaterial
@export var mesh : MeshInstance3D


func outline_parent(do:bool, _mesh:MeshInstance3D=null):
	if _mesh:
		if do:
			print(_mesh)
			_mesh.material_overlay = outline_shader_mat
			print(_mesh.material_overlay)
		else:
			_mesh.material_overlay = null
	else:
		if do:
			mesh.material_overlay = outline_shader_mat
		else:
			mesh.material_overlay = null
		
