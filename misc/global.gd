extends Node

const HALF_PI := PI / 2.0
const QUARTER_PI := PI / 4.0
const LARGE_FLOAT: float = 0x7FEFFFFFFFFFFFFF

func _ready():
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed('ui_cancel'):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
