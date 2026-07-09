extends Area3D

@export var safe_position := Vector3.ZERO

func _ready():
	collision_layer = 0
	collision_mask = 22 # layer 2, 3, 5
	area_entered.connect(_on_something_entered, CONNECT_DEFERRED)
	body_entered.connect(_on_something_entered, CONNECT_DEFERRED)

func _on_something_entered(something: CollisionObject3D):
	if something is CharacterBody3D:
		something.velocity = Vector3.ZERO
	elif something is RigidBody3D:
		something.linear_velocity = Vector3.ZERO
	something.global_position = safe_position
