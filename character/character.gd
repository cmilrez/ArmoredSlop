@abstract class_name Character extends CharacterBody3D

@export var data: CharacterData = null
@export var mass := 40.0
@export_enum('TeamA', 'TeamB', 'TeamC') var team_group := 'TeamB'
@export var lock_on_marker: Node3D = null
@export var weapons: Array[Node] = []

var alive := true
var boosting := false

func get_lock_position() -> Vector3:
	return lock_on_marker.global_position

func hor_direction(to: Vector3) -> Vector3:
	var dir = Vector2(global_position.x, global_position.z).direction_to(Vector2(to.x, to.z))
	return Vector3(dir.x, 0.0, dir.y)

func hor_distance(to: Vector3) -> float:
	return Vector2(global_position.x, global_position.z).distance_to(Vector2(to.x, to.z))

func do_friction(friction: float) -> void:
	var speed = velocity.length()
	if not speed:
		return
	var drop = speed * friction * get_process_delta_time()
	var new_speed = speed - drop
	if new_speed <= 0.0:
		new_speed = 0.0
	else:
		new_speed /= speed
	velocity.x *= new_speed
	velocity.z *= new_speed

func accelerate_up(wish_speed: float, accel: float) -> void:
	var diff = wish_speed - velocity.y
	if diff > 0.0:
		velocity.y += minf(diff, wish_speed * accel * get_process_delta_time())

func accelerate(wish_dir: Vector3, wish_speed: float, accel: float) -> void:
	#var h_vel = Vector3(velocity.x, 0.0, velocity.z)
	#var vel_diff = (wish_dir * wish_speed) - h_vel
	#var speed_diff = vel_diff.length()
	#if is_zero_approx(speed_diff):
		#return
	#var acceleration = minf(speed_diff, wish_speed * accel * get_process_delta_time())
	#velocity += acceleration * vel_diff / speed_diff
	
	var add_speed = wish_speed - velocity.dot(wish_dir)
	if add_speed <= 0.0:
		return
	var acceleration = minf(add_speed, wish_speed * accel * get_process_delta_time())
	velocity += acceleration * wish_dir
