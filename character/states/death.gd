extends State

func start(node):
	node.move_direction = Vector3.ZERO
	node.lock_on_marker.hide()
	node.look_at_mod.active = false

func exit(node):
	pass

func update(node, delta):
	pass

func physics_update(node, delta):
	pass

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
