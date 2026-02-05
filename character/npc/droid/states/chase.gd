extends State

@export var targeting: Targeting = null

func start(node):
	pass

func exit(node):
	pass

func update(node, delta):
	pass

func physics_update(node, delta):
	var distance: float = node.global_position.distance_squared_to(targeting.global_position)
	var direction: Vector3 = targeting.global_position - node.global_position
	direction = direction.normalized()
	if distance < 400.0: # 20
		node.move_direction = -direction
	elif distance < 1600.0: # 40
		var side = -node.global_basis.x.dot(direction)
		node.move_direction = direction.rotated(Vector3.UP, signf(side) * PI/2.0)
	else:
		node.move_direction = direction
	#if attack_timer.is_stopped():
		#var target = vision.target
		#for spawner in projectile_spawners:
			#if not is_instance_valid(target): return
			#if state == Actions.DIE: return
			#if spawner is BulletSpawner:
				#spawner.shoot_projectile(self, target_marker.global_position, projectile_scene)
			#elif spawner is MissileSpawner:
				#spawner.shoot_missile(self, target.lock_on_marker, target_marker.global_position, projectile_scene)
			#var muzzle_flash: Node3D = spawner.find_child('MuzzleFlash')
			#if muzzle_flash:
				#muzzle_flash.show()
				#get_tree().create_timer(0.1).timeout.connect(func (): muzzle_flash.hide())
			#if shot_sound and gun_type == Guns.CANNON:
				#var new_shot_sound: AudioStreamPlayer3D = shot_sound.instantiate()
				#new_shot_sound.pitch_scale += randf_range(-0.05, 0.05)
				#spawner.add_child(new_shot_sound)
				#new_shot_sound.finished.connect(func (): new_shot_sound.queue_free())
			#attack_timer.start(0.3)
			#await attack_timer.timeout
		#if gun_type == Guns.CANNON:
			#attack_timer.start(3.0)
		#elif gun_type == Guns.MISSILE:
			#attack_timer.start(5.0)

func input_event(node, event):
	pass

func key_input_event(node, event):
	pass
