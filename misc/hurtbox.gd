class_name Hurtbox extends Area3D

@export var damage_data: DamageData = null

func _ready():
	input_ray_pickable = false
	monitoring = false
	collision_layer = 64 # layer 6
	collision_mask = 8 # layer 4
