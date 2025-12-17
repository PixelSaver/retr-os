extends Node2D

const GRID_SIZE := Vector2i(32, 16)  # Small grid to start
const CELL_SIZE = 32  # Pixels per cell (for drawing)
const SHADER_FILE_PATH = "res://Shaders/acoustic_wave.glsl"

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var uniform_set_a: RID
var uniform_set_b: RID

var pressure_data_a: PackedFloat32Array
var pressure_data_b: PackedFloat32Array
var vel_x_data: PackedFloat32Array
var vel_y_data: PackedFloat32Array
var buffer_p_a: RID
var buffer_p_b: RID
var buffer_x: RID
var buffer_y: RID

# QoL stuff
var position_offset : Vector2
var use_a_as_input := true # Toggles for swapping set a and b for double buffering

# Playback controls
var is_playing := false
var max_fps := 60
var frame_counter := 0
var fps_display := 0
var time_accumulator := 0.0

func _ready() -> void:
	rd = RenderingServer.create_local_rendering_device()
	if not rd:
		push_error("GPU compute and rendering server not supported")
		return
	
	# QoL stuff
	position_offset = get_viewport_rect().size / 2
	position_offset -= Vector2(GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE) / 2.
	
	# THIS IS WAHT THE DOCS SAID HELP https://docs.godotengine.org/en/latest/tutorials/shaders/compute_shaders.html
	var shader_file := load(SHADER_FILE_PATH)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	setup_buffers()
	
	# Cycle
	run_compute_shader()
	
	read_data_from_gpu()
	
	# Start in paused state
	is_playing = false
	queue_redraw()

func setup_buffers():
	# Initialize arrays
	pressure_data_a = PackedFloat32Array()
	pressure_data_a.resize(GRID_SIZE.x * GRID_SIZE.y)
	pressure_data_a.fill(0.0)
	pressure_data_b = PackedFloat32Array()
	pressure_data_b.resize(GRID_SIZE.x * GRID_SIZE.y)
	pressure_data_b.fill(0.0)

	vel_x_data = PackedFloat32Array()
	vel_x_data.resize(GRID_SIZE.x * GRID_SIZE.y)
	vel_x_data.fill(0.0)

	vel_y_data = PackedFloat32Array()
	vel_y_data.resize(GRID_SIZE.x * GRID_SIZE.y)
	vel_y_data.fill(0.0)

	# Create GPU storage buffers from the arrays (use their byte representations)
	var bytes_p_a := pressure_data_a.to_byte_array()
	buffer_p_a = rd.storage_buffer_create(bytes_p_a.size(), bytes_p_a)
	var bytes_p_b := pressure_data_b.to_byte_array()
	buffer_p_b = rd.storage_buffer_create(bytes_p_b.size(), bytes_p_b)

	var bytes_x := vel_x_data.to_byte_array()
	buffer_x = rd.storage_buffer_create(bytes_x.size(), bytes_x)

	var bytes_y := vel_y_data.to_byte_array()
	buffer_y = rd.storage_buffer_create(bytes_y.size(), bytes_y)

	# Create RDUniform entries for each storage buffer (bindings must match shader)
	var uniform0 = RDUniform.new()
	uniform0.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform0.binding = 0
	uniform0.add_id(buffer_p_a)
	var uniform1 = RDUniform.new()
	uniform1.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform1.binding = 1
	uniform1.add_id(buffer_p_b)

	var uniform2 = RDUniform.new()
	uniform2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform2.binding = 2
	uniform2.add_id(buffer_x)

	var uniform3 = RDUniform.new()
	uniform3.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform3.binding = 3
	uniform3.add_id(buffer_y)

	# Two unifroms to double buffer, swap a and b for shader to write to
	uniform_set_a = rd.uniform_set_create([uniform0, uniform1, uniform2, uniform3], shader, 0)
	uniform_set_b = rd.uniform_set_create([uniform1, uniform0, uniform2, uniform3], shader, 0)

# The plan 
func _process(delta: float) -> void:
	if not rd: return
	
	handle_input()
	update_fps_counter(delta)
	
	# Only run simulation if playing and we have time
	if is_playing:
		var frame_time = 1.0 / max_fps
		time_accumulator += delta
		
		#while time_accumulator >= frame_time:
		if true:
			run_compute_shader()
			read_data_from_gpu()
			time_accumulator -= frame_time
			frame_counter += 1
			queue_redraw()
			print("ran %s" % Time.get_unix_time_from_system())

func handle_input() -> void:
	# Playing and pausing
	if Input.is_action_just_pressed("ui_select"):
		is_playing = !is_playing
	
	# Right arrow to frame forward
	if Input.is_action_just_pressed("ui_right"):
		run_compute_shader()
		read_data_from_gpu()
		frame_counter += 1
		queue_redraw()
	
	# Left arrow to frame backward but cant rn so placeholder
	if Input.is_action_just_pressed("ui_left"):
		#TODO Implement frame history for a few frames
		is_playing = false
		push_error("Frame back not yet implemented - would need frame history")
	
	# Change max FPS with up/down arrows
	if Input.is_action_just_pressed("ui_up"):
		max_fps = min(max_fps + 10, 240)
	
	if Input.is_action_just_pressed("ui_down"):
		max_fps = max(max_fps - 10, 10)

## FPS Counter 
func update_fps_counter(delta: float) -> void:
	time_accumulator += delta
	if time_accumulator >= 0.5:
		fps_display = roundi(1.0 / delta)
		time_accumulator -= 0.5

func run_compute_shader():
	# Push constants AKA params AKA uniforms WHY SO MANY NAMES
	var push_constant = PackedByteArray()
	# Apparently theres rules, you have to do this in 16...
	push_constant.resize(16)
	push_constant.encode_s32(0, GRID_SIZE.x)
	push_constant.encode_s32(4, GRID_SIZE.y)
	var time_seconds = fmod(Time.get_ticks_usec() / 1000000.0, 100.0)
	push_constant.encode_float(8, time_seconds)
	
	print("Time being passed: ", time_seconds)
	
	# Create a compute pipeline (from docs)
	# Leymans terms: RUN THE SHADER RHAHHH
	var compute_list : int = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	var active_uniform_set = uniform_set_a if use_a_as_input else uniform_set_b
	rd.compute_list_bind_uniform_set(compute_list, active_uniform_set, 0)
	rd.compute_list_set_push_constant(compute_list, push_constant, push_constant.size())
	
	# Dispatch AKA GOOOOOOOO but 8x8 threads for now
	var groups_x := ceili(float(GRID_SIZE.x) / 8.0)
	var groups_y := ceili(float(GRID_SIZE.y) / 8.0)
	rd.compute_list_dispatch(compute_list, groups_x, groups_y, 1)
	
	# Submit to GPU and wait for sync
	rd.compute_list_end()
	rd.submit()
	rd.sync()

func read_data_from_gpu():
	var buffer_to_read = buffer_p_b if use_a_as_input else buffer_p_a
	var output_bytes = rd.buffer_get_data(buffer_to_read)
	pressure_data_a = output_bytes.to_float32_array()
	use_a_as_input = !use_a_as_input

# Visualize the grid
func _draw() -> void:
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var index = y * GRID_SIZE.x + x
			var value = pressure_data_a[index]
			
			# Normalize pressure to visible range (-1 to 1 maps to 0 to 1)
			var normalized = clamp(value * 2.0 + 0.5, 0.0, 1.0)
			
			# Map a value 0-1 with greyscale
			var color = Color(normalized, normalized, normalized, 1.0)
			
			var rect = Rect2(x * CELL_SIZE + position_offset.x, y * CELL_SIZE + position_offset.y, CELL_SIZE - 1, CELL_SIZE - 1)
			draw_rect(rect, color)

# Cleanup just in case
func _exit_tree():
	if rd:
		rd.free_rid(buffer_p_a)
		rd.free_rid(buffer_p_b)
		rd.free_rid(buffer_x)
		rd.free_rid(buffer_y)
		rd.free_rid(uniform_set_a)
		rd.free_rid(uniform_set_b)
		rd.free_rid(pipeline)
		rd.free_rid(shader)
		rd.free()
