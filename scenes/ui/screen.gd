extends SubViewport
class_name Screen

@export var screen_mesh : MeshInstance3D
@export var subviewport : SubViewport


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return

	# 1. Translate 3D World Position to Local Quad UV Coordinates (0.0 to 1.0)
	
	# Invert the quad's global transform to get the local coordinates of the click
	var local_click = screen_mesh.global_transform.affine_inverse() * event_position
	
	var viewport_size = subviewport.size
	var mesh_size = (screen_mesh.mesh as QuadMesh).size
	
	# Map the local coordinates (assumed to be from -0.5 to 0.5) to UV space (0.0 to 1.0)
	# The X/Y mapping depends on how your quad's mesh is oriented.
	var u_coord = local_click.x + mesh_size.x/2.   # X -> U (Width)
	u_coord /= mesh_size.x
	# Y is usually flipped for UI, so we subtract from 0.5
	var v_coord = mesh_size.y/2. - local_click.y   # Y -> V (Height)
	v_coord /= mesh_size.y
	print("UV: ", str(Vector2(u_coord, v_coord)))
	# Check if the coordinates are within the quad's bounds (e.g., -0.5 to 0.5)
	if u_coord < 0.0 or u_coord > 1.0 or v_coord < 0.0 or v_coord > 1.0:
		return
	
	# Screen position is the pixel coordinates within the viewport
	var screen_pos = Vector2(
		u_coord * viewport_size.x, 
		v_coord * viewport_size.y
	)

	# 3. Create a new event and push it to the SubViewport
	
	var new_event = event.duplicate()
	
	if new_event is InputEventMouse:
		new_event.position = screen_pos
		new_event.global_position = screen_pos
		
		# For motion events, the 'relative' property is usually calculated
		# based on the difference from the last frame. For simplicity here, 
		# we can skip setting 'relative' or just set it to zero for now.
		
	# Pushing the event sends it directly to the UI Control nodes
	subviewport.push_input(new_event)
	
	# Tell the main 3D viewport that the input has been used
	get_viewport().set_input_as_handled()
