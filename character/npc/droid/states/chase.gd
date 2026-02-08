extends State

@onready var timer = $Timer

@export var gun: Node = null
@export var targeting: Targeting = null

func start(node):
	timer.start(0.1)

func exit(node):
	timer.stop()

func update(node, delta):
	pass

func physics_update(node, delta):
	var distance: float = node.global_position.distance_squared_to(targeting.global_position)
	var direction: Vector3 = targeting.global_position - node.global_position
	direction = direction.normalized()
	if distance < 900.0: # 30
		node.move_direction = -direction
	elif distance < 3600.0: # 60
		var side = -node.global_basis.x.dot(direction)
		node.move_direction = direction.rotated(Vector3.UP, signf(side) * PI/2.0)
	else:
		node.move_direction = direction
	if timer.is_stopped():
		gun.activate(targeting)
		timer.start(3.0)

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
