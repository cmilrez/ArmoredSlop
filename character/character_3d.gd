@abstract class_name Character3D extends CharacterBody3D

enum Teams {
	## Player Team
	TEAM_A,
	## Enemy Team
	TEAM_B,
	## Free for All Team
	TEAM_C}

@export var mass := 80.0
@export var team := Teams.TEAM_B
@export var lock_on_marker: Node3D = null
@export var weapons: Array[Weapon3D] = []

var move_direction := Vector3.ZERO
var speed := 40.0
var alive := true

func is_same_team(other_team: Teams) -> bool:
	return other_team == team and not other_team == Teams.TEAM_C

func get_lock_position() -> Vector3:
	return lock_on_marker.global_position

func lock_distance_to(to: Vector3) -> float:
	return get_lock_position().distance_to(to)

func lock_direction_to(to: Vector3) -> Vector3:
	return get_lock_position().direction_to(to)

func hor_direction(to: Vector3) -> Vector3:
	var dir = Vector2(position.x, position.z).direction_to(Vector2(to.x, to.z))
	return Vector3(dir.x, 0.0, dir.y)

func hor_distance(to: Vector3) -> float:
	return Vector2(position.x, position.z).distance_to(Vector2(to.x, to.z))

func hor_angle(to: Vector3) -> float:
	var to_2d = Vector2(to.z, to.x)
	if to_2d.is_zero_approx():
		return 0.0
	return Vector2(basis.z.z, basis.z.x).angle_to(to_2d)

func do_friction(friction: float) -> void:
	var current_speed = velocity.length()
	if not current_speed:
		return
	var drop = current_speed * friction * get_physics_process_delta_time()
	var new_speed = current_speed - drop
	if new_speed <= 0.0:
		new_speed = 0.0
	else:
		new_speed /= current_speed
	velocity.x *= new_speed
	velocity.z *= new_speed

func accelerate_up(wish_speed: float, accel: float) -> void:
	var diff = wish_speed - velocity.y
	if diff > 0.0:
		velocity.y += minf(diff, wish_speed * accel * get_physics_process_delta_time())

func accelerate(wish_dir: Vector3, wish_speed: float, accel: float) -> void:
	var add_speed = wish_speed - velocity.dot(wish_dir)
	if add_speed <= 0.0:
		return
	var acceleration = minf(add_speed, wish_speed * accel * get_physics_process_delta_time())
	velocity += acceleration * wish_dir
	
	# linear, boring
	#var vel_diff = (wish_dir * wish_speed) - velocity
	#var speed_diff = vel_diff.length()
	#if not speed_diff:
		#return
	#var acceleration = minf(speed_diff, wish_speed * accel * get_physics_process_delta_time())
	#velocity += acceleration * vel_diff / speed_diff

func push_rigid_body_3d() -> void:
	if not velocity:
		return
	const MAX_STEPS := 3
	for i in get_slide_collision_count():
		if i >= MAX_STEPS:
			return
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if not collider is RigidBody3D:
			continue
		var mass_ratio =  mass / collider.mass
		if mass_ratio <= 0.0:
			continue
		var push_direction = -collision.get_normal()
		var velocity_diff = velocity.dot(push_direction) - collision.get_collider_velocity().dot(push_direction)
		if velocity_diff <= 0.0:
			continue
		var collision_point = collision.get_position()
		var push_force = mass * mass_ratio
		collider.apply_impulse(push_direction * velocity_diff * push_force, collision_point - collider.global_position)
