extends State

signal attack_started

@onready var targeting = %Targeting
@onready var timer = $Timer

@export var forward_speed := 40.0
@export var time_limit := 1.5
var target: Character = null

func _ready():
	timer.one_shot = true
	timer.timeout.connect(func(): attack_started.emit())

func start(node):
	target = targeting.target
	timer.start(time_limit)

func exit(node):
	target = null
	timer.stop()

func update(node, delta):
	pass

func physics_update(node, delta):
	var direction = Vector3.ZERO
	if target:
		var distance = node.global_position.distance_squared_to(target.global_position)
		if distance < 81.0:
			if not timer.is_stopped():
				timer.stop()
				attack_started.emit()
		else:
			direction = node.lock_on_marker.global_position.direction_to(target.lock_on_marker.global_position)
			node.global_rotation.y = Vector2(direction.z, direction.x).angle() - PI
	else:
		direction = -node.global_basis.z
	node.velocity = direction * forward_speed

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
