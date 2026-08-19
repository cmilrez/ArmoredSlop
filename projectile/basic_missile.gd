extends Missile

func _physics_process(delta):
	if move_and_collide(data.speed):
		hitspawn_and_damage()
		destroy()
	else:
		rotate_to_target()
