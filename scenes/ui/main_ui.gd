extends CanvasLayer
class_name MainUI

const GAME_FILES_DIR = "user://game_files"
const DEFAULT_GAME_PAGE = "user://game_files/default_page.html"
const SAVED_GAME_PAGE = "user://game_files/saved_page.html"
const HOME_PAGE = "https://github.com/Lecrapouille/gdcef"
const RADIO_PAGE = "http://streaming.radio.co/s9378c22ee/listen"
		
var par: SubViewport
@export var main_menu: Control
@export var computer_ui: Control
@onready var theme: Control = $Theme
@onready var window_container: Control = $Theme/GUI/WindowContainer
@onready var gui = $Theme/GUI
@onready var os_window_scene = preload("res://scenes/ui/window/os_window.tscn")

var active_windows: Array[OSWindow] = []

func _ready() -> void:
	Global.main_ui = self
	par = get_parent() as SubViewport
	
	setup_game_files()

## Create the game_files directory and populate it
func setup_game_files():
	var dir = DirAccess.open("user://")
	
	# Create the directory if it doesn't exist
	if not dir.dir_exists("game_files"):
		var err = dir.make_dir("game_files")
		if err != OK:
			push_error("Failed to create game_files directory: " + str(err))
			return
	create_page("user://game_files/default_page.html", "<html><body bgcolor=\"white\"><h2>Welcome to Retr-OS!</h2><p>This is a generated page in game_files directory.</p></body></html>")
	create_page("user://game_files/holidays.html", "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Happy Holidays!</title><style>body{margin:0;padding:0;background:linear-gradient(to bottom,#1a1a2e 0%,#0f3460 100%);font-family:'Arial',sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;overflow:hidden}.container{text-align:center;color:white}h1{font-size:4em;margin:0;animation:fadeInScale 2s ease-out}.snowflake{position:absolute;top:-10px;color:white;font-size:1.5em;animation:fall linear infinite;opacity:0.8}@keyframes fall{to{transform:translateY(100vh) rotate(360deg)}}@keyframes fadeInScale{from{opacity:0;transform:scale(0.5)}to{opacity:1;transform:scale(1)}}.message{font-size:1.5em;margin-top:20px;animation:fadeIn 3s ease-in 1s both}@keyframes fadeIn{from{opacity:0}to{opacity:1}}.star{display:inline-block;animation:twinkle 1.5s ease-in-out infinite}@keyframes twinkle{0%,100%{opacity:1}50%{opacity:0.3}}</style></head><body><div class=\"container\"><h1><span class=\"star\">*</span> Happy Holidays! <span class=\"star\">*</span></h1><p class=\"message\">Wishing you joy and warmth this season</p></div><script>function createSnowflake(){const snowflake=document.createElement('div');snowflake.classList.add('snowflake');snowflake.innerHTML='*';snowflake.style.left=Math.random()*100+'%';snowflake.style.animationDuration=(Math.random()*3+2)+'s';snowflake.style.fontSize=(Math.random()*1+0.5)+'em';document.body.appendChild(snowflake);setTimeout(()=>{snowflake.remove()},5000)}setInterval(createSnowflake,200)</script></body></html>")
	
	# Copy HELP.md
	var src_path := "res://HELP.md"
	var dst_path := "user://game_files/HELP.md"
	var src := FileAccess.open(src_path, FileAccess.READ)
	var content := src.get_as_text()
	src.close()
	var dst := FileAccess.open(dst_path, FileAccess.WRITE)
	dst.store_string(content)
	dst.close()

func create_page(path:String, content:String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	else:
		push_error("Failed to create page at path: %s" % path)

## Run a program by ID (from ProgramManager)
func run_program_by_id(program_id: String, args:Array=[], init_pos: Vector2 = Vector2.ONE * -1, window_size: Vector2 = Vector2(-1, -1)) -> OSWindow:
	var prog = ProgramManager.create_program(program_id)
	if not prog:
		push_error("Failed to create program: " + program_id)
		return null
	
	return run_program(prog, args, init_pos, window_size)

## Run a program instance directly
func run_program(prog: Program, args:Array=[], init_pos: Vector2 = Vector2.ONE * -1, window_size: Vector2 = Vector2(-1,-1)) -> OSWindow:
	var window := os_window_scene.instantiate() as OSWindow
	window_container.add_child(window)
	window.custom_init(window_size, init_pos)
	window.load_program(prog, args)
	
	active_windows.append(window)
	window.tree_exiting.connect(_on_window_closed.bind(window))
	
	return window

func _on_window_closed(window: OSWindow) -> void:
	var idx = active_windows.find(window)
	if idx >= 0:
		active_windows.remove_at(idx)

func put_on_top(control: Control) -> void:
	var parent = control.get_parent()
	if parent:
		parent.move_child(control, parent.get_child_count())

## Get all running windows for a specific program type
func get_windows_by_program_id(program_id: String) -> Array[OSWindow]:
	var result: Array[OSWindow] = []
	for window in active_windows:
		if window.held_program and window.held_program.program_id == program_id:
			result.append(window)
	return result

## Close all instances of a program
func close_program_instances(program_id: String) -> void:
	var windows = get_windows_by_program_id(program_id)
	for window in windows:
		window.queue_free()


func _on_window_button_pressed(button: WindowButton) -> void:
	print(button.name.to_lower())
	match button.name.to_lower():
		"start":
			run_program_by_id("template")
		"file":
			pass
