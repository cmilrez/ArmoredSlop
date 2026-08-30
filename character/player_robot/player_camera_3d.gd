class_name PlayerCamera3D extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var eye_ray: RayCast3D = $EyeRay
@onready var tracker: Tracker3D = %Tracker3D
@onready var player: Robot3D = get_parent()

@export_range(0.01, 1.0, 0.01, 'or_greater', 'hide_control') var mouse_sensitivity := 0.02
@export_range(-1, 1, 2) var invert_y := -1
@export_range(-1, 1, 2) var invert_x := -1
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var max_angle_x := PI / 2
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var min_angle_x := -PI / 2
@export_range(0.0, 20.0, 0.1, 'or_greater', 'hide_control') var arm_length := 12.0
@export_range(0.0, 20.0, 0.1, 'or_greater', 'hide_control') var height := 11.0
#@export var lock_on_data: LockOnData = null

var target_list: Array[Character3D] = []
var multi_target_list: Array[Character3D] = []
var input_direction := Vector2.ZERO
var manual_aim := false
var multi_target_count := 0:
	set(value):
		multi_target_count = maxi(value, 0)
		if not multi_target_count:
			multi_target_list.clear()

func _append_target(node: Character3D) -> void:
	target_list.append(node)

func _erase_target(node: Character3D) -> void:
	target_list.erase(node)

func _ready():
	SignalBus.enemy_entered_screen.connect(_append_target)
	SignalBus.enemy_exited_screen.connect(_erase_target)
	spring_arm.spring_length = arm_length
	top_level = true

func get_unprojected(world_pos: Vector3) -> Vector2:
	return camera.unproject_position(world_pos)

func get_arm_rotation() -> float:
	return spring_arm.rotation.y

func is_target_invalid(node: Character3D, unprojected_pos: Vector2) -> bool:
	if not is_instance_valid(node):
		return true
	if player.is_same_team(node.team):
		return true
	var node_position = node.get_lock_position()
	var distance = global_position.distance_to(node_position)
	if distance > player.data.lock_on.distance:
		return true
	eye_ray.target_position = eye_ray.to_local(node_position)
	eye_ray.force_raycast_update()
	if eye_ray.is_colliding():
		return true
	if not player.data.lock_on.region.has_point(unprojected_pos):
		return true
	return false

func _search_single_target() -> Character3D:
	var closest_target: Character3D = null
	var closest_distance_2d = Global.LARGE_FLOAT
	for target in target_list:
		var pos_2d = camera.unproject_position(target.get_lock_position())
		if is_target_invalid(target, pos_2d):
			continue
		var target_distance_2d = pos_2d.distance_to(player.data.lock_on.region.get_center())
		if target_distance_2d < closest_distance_2d:
			closest_target = target
			closest_distance_2d = target_distance_2d
	return closest_target

func _search_multi_targets() -> Array[Character3D]:
	var list: Array[Character3D] = []
	var i = 1
	for target in target_list:
		if i > multi_target_count:
			break
		if target == tracker.target:
			continue
		var pos_2d = camera.unproject_position(target.get_lock_position())
		if is_target_invalid(target, pos_2d):
			continue
		list.append(target)
		i += 1
	return list

func _process(delta):
	if not camera.current:
		return
	spring_arm.rotation.x += input_direction.y * delta * invert_y
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_angle_x, max_angle_x)
	spring_arm.rotation.y += input_direction.x * delta * invert_x
	input_direction = Vector2.ZERO

func _physics_process(delta):
	if not camera.current:
		return
	var lerp_weight = exp(-8.0 * delta)
	position.x = lerpf(player.position.x, position.x, lerp_weight)
	position.z = lerpf(player.position.z, position.z, lerp_weight)
	var lerp_weight2 = exp(-4.0 * delta)
	position.y = lerpf(player.position.y + height, position.y, lerp_weight2)
	
	eye_ray.global_position = camera.global_position
	var new_target: Character3D = null
	if not tracker.lock_target:
		if not manual_aim:
			new_target = _search_single_target()
			if multi_target_count:
				multi_target_list = _search_multi_targets()
		tracker.target = new_target
		if not new_target:
			eye_ray.target_position = -camera.global_basis.z * Global.LARGE_FLOAT
			var point = to_global(eye_ray.target_position)
			eye_ray.force_raycast_update()
			if eye_ray.is_colliding():
				point = eye_ray.get_collision_point()
			tracker.position = point

func _unhandled_input(event):
	if not camera.current:
		return
	if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		input_direction = event.screen_relative * mouse_sensitivity
	elif event.is_action_pressed('manual_aim'):
		manual_aim = not manual_aim
