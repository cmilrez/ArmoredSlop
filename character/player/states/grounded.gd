class_name Grounded extends State

@export var speed := 40.0
var speed_multiplier := Vector2.ZERO

func start(node):
	speed_multiplier = Vector2(node.move_direction.x, node.move_direction.z)

func exit(node):
	speed_multiplier *= 0.0

func update(node, delta):
	pass

func physics_update(node, delta: float):
	if node.move_direction:
		var weight = 1.0 - pow(0.5, delta * 4.0)
		speed_multiplier.x = lerpf(speed_multiplier.x, node.move_direction.x, weight)
		speed_multiplier.y = lerpf(speed_multiplier.y, node.move_direction.z, weight)
		node.velocity.x = speed_multiplier.x * speed
		node.velocity.z = speed_multiplier.y * speed
	else:
		speed_multiplier *= 0
		var weight := 1.0 - pow(0.5, delta * 8.0)
		node.velocity.x = lerpf(node.velocity.x, 0.0, weight)
		node.velocity.z = lerpf(node.velocity.z, 0.0, weight)

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
