extends Node

signal game_state_changed(new_state:States)
enum States {
	MENU,
	SETTINGS,
	RADIO,
	END,
}
var state : States = States.MENU :
	set(val):
		if val == state: return
		state = val
		game_state_changed.emit(val)
		
# Make world root easy to access
var world_root : WorldRoot 
