extends State

@onready var timer = $Timer

func start(node):
	pass

func exit(node):
	pass

func update(node, delta):
	pass

func physics_update(node, delta):
	if node.global_position.distance_squared_to(node.home_position) > 6400.0:
		var direction_to_home = node.global_position.direction_to(node.home_position)
		node.move_direction = direction_to_home
		return
	if not timer.is_stopped():
		return
	var rand := randf_range(-1.0, 1.0)
	node.move_direction = Vector3.FORWARD.rotated(Vector3.UP, rand * PI)
	timer.start(maxf(5.0, 15.0 * absf(rand)))

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
