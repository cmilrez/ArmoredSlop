extends State

@export var jump_power := 20.0
@export var speed := 40.0
@export var upward_speed := 30.0

func start(node):
	pass

func exit(node):
	pass

func update(node, delta):
	node.activate_units()

func physics_update(node, delta):
	if node.move_direction.y:
		if node.is_on_floor():
			node.velocity.y = jump_power
		else:
			node.velocity.y = upward_speed
	else:
		node.velocity += node.gravity * delta * 6.0
	if node.move_direction.x or node.move_direction.z:
		node.velocity += node.accelerate(node.move_direction, speed, delta)
	else:
		node.velocity.x -= node.velocity.x * delta * 2.0
		node.velocity.z -= node.velocity.z * delta * 2.0
	node.face_camera(delta)

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
