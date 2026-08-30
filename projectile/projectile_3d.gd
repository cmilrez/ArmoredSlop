@abstract class_name Projectile3D extends ShapeCast3D

const LIFE_TIME = 10.0

@onready var timer: Timer = $Timer

@export var hitspawn_scene: PackedScene = null
var damage_data: DamageData = null

@abstract func set_up(spawn: Node3D, dmg_data: DamageData, target_pos: Vector3, _target: Character3D = null) -> void

func _ready():
	top_level = true
	enabled = false
	collide_with_areas = true
	collision_mask = 11 # layer 1, 2, 4
	max_results = 1
	timer.one_shot = true
	timer.timeout.connect(destroy)
	timer.start(LIFE_TIME)

func hitspawn_and_damage() -> void:
	if hitspawn_scene:
		var collision_point = get_collision_point(0)
		var node = hitspawn_scene.instantiate()
		get_tree().current_scene.add_child(node)
		if node is Explosion3D:
			node.set_up(collision_point, damage_data)
		elif node is VFXContainer3D:
			node.set_up(collision_point, get_collision_normal(0))
			var collider = get_collider(0)
			if collider is Hitbox3D:
				collider.hit.emit(damage_data)
	else:
		var collider = get_collider(0)
		if collider is Hitbox3D:
			collider.hit.emit(damage_data)

func destroy() -> void:
	timer.stop()
	queue_free()

func move_and_collide(speed: float) -> bool:
	var delta_speed = speed * get_physics_process_delta_time()
	target_position.z = delta_speed
	force_shapecast_update()
	position += basis.z * delta_speed
	return is_colliding()

func get_prediction(bullet_speed: float, target: Character3D) -> Vector3:
	#if not is_instance_valid(target): # assume there is always a target
		#return Vector3.ZERO
	var target_velocity = target.get_real_velocity()
	var target_velocity_length_squared = target_velocity.length_squared()
	var target_pos = target.get_lock_position()
	if not target_velocity_length_squared:
		return target_pos
	var time := 0.0
	# will never hit if slower
	if bullet_speed * bullet_speed > target_velocity_length_squared:
		var to_target = target_pos - position
		if to_target:
			var a = bullet_speed * bullet_speed - target_velocity_length_squared
			var b = 2.0 * target_velocity.dot(to_target)
			var c = to_target.length_squared()
			time = (b + sqrt(b * b + 4.0 * a * c)) / (2.0 * a)
	return target_pos + time * target_velocity
