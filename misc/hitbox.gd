class_name Hitbox extends Area3D

signal hit(damage_data: DamageData)

func _ready():
	input_ray_pickable = false
	collision_layer = 8 # layer 4
	collision_mask = 64 # layer 6
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	if area is Hurtbox:
		hit.emit(area.damage_data)
