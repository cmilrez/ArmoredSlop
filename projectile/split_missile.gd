extends Missile

@onready var spawners = $Spawners

@export_range(0.0, 100.0, 0.001, 'or_greater', 'suffix:m') var detonation_distance := 20.0

func _process(delta):
	if position.distance_squared_to(targeting.position) < detonation_distance * detonation_distance:
		if hitspawn_scene:
			for spawn in spawners.get_children():
				var node: Missile = hitspawn_scene.instantiate()
				get_tree().current_scene.add_child(node)
				node.set_up(spawn, damage_data, targeting.position, targeting.target)
		else:
			var collider = ray_cast.get_collider()
			if collider is Hitbox:
				collider.hit.emit(damage_data)
		timer.stop()
		destroy()
		return
	if move_and_collide():
		timer.stop()
		destroy()
		return
	rotate_to_target(false)
