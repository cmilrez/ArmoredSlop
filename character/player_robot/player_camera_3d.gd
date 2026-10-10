class_name PlayerCamera3D extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var eye_ray: RayCast3D = $EyeRay
@onready var tracker: Tracker3D = %Tracker3D
@onready var player: Robot3D = get_parent()
@onready var robot_hud: RobotHUD = %RobotHUD

@export_range(0.01, 1.0, 0.01, 'or_greater', 'hide_control') var mouse_sensitivity := 0.3
@export_range(-1, 1, 2) var invert_y := -1
@export_range(-1, 1, 2) var invert_x := -1
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var max_angle_x := PI / 2
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var min_angle_x := -PI / 2
@export_range(0.0, 20.0, 0.1, 'or_greater', 'hide_control') var arm_length := 13.0
@export_range(0.0, 20.0, 0.1, 'or_greater', 'hide_control') var height := 12.0

var target_ctx: TargetContext = null
var target_list: Array[Character3D] = []
var target_count := 1
var input_direction := Vector2.ZERO
var auto_lock := true

func _append_target(node: Character3D) -> void:
	target_list.push_back(node)

func _erase_target(node: Character3D) -> void:
	target_list.erase(node)

func _ready():
	SignalBus.enemy_entered_screen.connect(_append_target)
	SignalBus.enemy_exited_screen.connect(_erase_target)
	spring_arm.spring_length = arm_length
	top_level = true
	target_ctx = player.target_ctx
	target_ctx.tracker = tracker

func get_unprojected(world_pos: Vector3) -> Vector2:
	return camera.unproject_position(world_pos)

func get_arm_rotation() -> float:
	return spring_arm.rotation.y

func is_target_invalid(node: Character3D, unprojected_pos: Vector2) -> bool:
	if not is_instance_valid(node):
		return true
	if not node.alive:
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
	if not robot_hud.lock_on_rect.has_point(unprojected_pos):
		return true
	return false

func _search_targets() -> void:
	target_ctx.list.clear()
	var closest_target: Character3D = null
	var closest_distance_2d = Global.LARGE_FLOAT
	var extra_count = 1
	for target in target_list:
		var pos_2d = camera.unproject_position(target.get_lock_position())
		if is_target_invalid(target, pos_2d):
			continue
		var target_distance_2d = pos_2d.distance_to(robot_hud.lock_on_rect.get_center())
		if target_distance_2d < closest_distance_2d:
			closest_target = target
			closest_distance_2d = target_distance_2d
		if extra_count < target_count:
			if not target == closest_target:
				target_ctx.list.push_back(target)
				extra_count += 1
	if closest_target:
		target_ctx.list.push_back(closest_target)
		target_ctx.index = target_ctx.list.size() - 1
	else:
		target_ctx.index = -1

func _process(delta):
	if not camera.current:
		return
	spring_arm.rotation.x += input_direction.y * invert_y
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_angle_x, max_angle_x)
	spring_arm.rotation.y += input_direction.x * invert_x
	input_direction = Vector2.ZERO
	
	var player_pos = player.position
	player_pos.y += height
	var dir = position - player_pos
	var limit = Vector3(10.0, height, 10.0)
	dir = dir.clamp(-limit, limit)
	position = player_pos + dir
	
	if player.state == player.ARM_RECOIL or player.state == player.BACK_RECOIL:
		var side = signf(Vector2(dir.x, dir.z).rotated(player.rotation.y).x)
		player_pos += player.basis.x * 4.0 * side
		player_pos -= player.basis.z * 4.0
	var lerp_weight = exp(-4.0 * delta)
	position.x = lerpf(player_pos.x, position.x, lerp_weight)
	position.z = lerpf(player_pos.z, position.z, lerp_weight)
	var lerp_weight2 = exp(-3.0 * delta)
	position.y = lerpf(player_pos.y, position.y, lerp_weight2)
	
	if not (tracker.lock_target and tracker.target):
		eye_ray.global_position = camera.global_position
		if auto_lock and target_count:
			_search_targets()
		if target_ctx.list.is_empty():
			tracker.target = null
		else:
			tracker.target = target_ctx.list[target_ctx.index]
		if not tracker.target:
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
		input_direction = event.screen_relative * mouse_sensitivity * 0.001
	elif event.is_action_pressed('manual_aim'):
		auto_lock = not auto_lock
