extends Node

var main_ui : MainUI

enum States {
	BOOT,
	GUI,
}
var os_state : States = States.GUI
