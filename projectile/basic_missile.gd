extends Missile

func _process(delta):
	if move_and_collide():
		if hitspawn_scene:
			var collision_point = ray_cast.get_collision_point()
			var node = hitspawn_scene.instantiate()
			get_tree().current_scene.add_child(node)
			if node is Explosion:
				node.set_up(collision_point, damage_data)
			elif node is VFXContainer:
				node.set_up(collision_point, ray_cast.get_collision_normal())
		else:
			var collider = ray_cast.get_collider()
			if collider is Hitbox:
				collider.hit.emit(damage_data)
		timer.stop()
		destroy()
		return
	rotate_to_target()
