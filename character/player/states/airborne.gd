class_name Airborne extends State

@export var jump_power := 20.0
@export var airborne_speed := 50.0
@export var upward_speed := 30.0
var speed_multiplier := Vector3.ZERO

func start(node):
	if node.move_direction.y:
		node.velocity.y = jump_power
	speed_multiplier = node.move_direction

func exit(node):
	speed_multiplier *= 0.0

func update(node, delta):
	pass

func physics_update(node, delta):
	if node.move_direction.y:
		speed_multiplier.y = move_toward(speed_multiplier.y, node.move_direction.y, 0.9)
		node.velocity.y = speed_multiplier.y * upward_speed
	else:
		speed_multiplier.y = 0.0
		node.velocity += node.gravity * delta * 6.0
	
	if node.move_direction.x or node.move_direction.z:
		var weight = 1 - pow(0.5, delta * 4.0)
		speed_multiplier.x = lerpf(speed_multiplier.x, node.move_direction.x, weight)
		speed_multiplier.z = lerpf(speed_multiplier.z, node.move_direction.z, weight)
		node.velocity.x = speed_multiplier.x * airborne_speed
		node.velocity.z = speed_multiplier.z * airborne_speed
	else:
		node.velocity = node.velocity.move_toward(Vector3(0.0, node.velocity.y, 0.0), 0.7)

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
