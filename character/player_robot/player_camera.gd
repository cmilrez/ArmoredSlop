class_name PlayerCamera extends Node3D

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var eye_ray = $EyeRay
@onready var player: Character = get_parent()
var targeting: Targeting = null

@export var mouse_sensitivity := 0.02
@export var invert_y := -1
@export var invert_x := -1
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var max_angle_x := PI / 2
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var min_angle_x := -PI / 2
@export var arm_length := 10.0
@export var height := 10.0
@export var lock_on_data: LockOnData = null

var target_list: Array[Node3D] = []
var input_direction := Vector2.ZERO
var manual_aim := false

func get_arm_rotation() -> float:
	return spring_arm.rotation.y

func _ready():
	targeting = player.find_child('Targeting', false)
	SignalBus.enemy_entered_screen.connect(_append_target)
	SignalBus.enemy_exited_screen.connect(_erase_target)
	spring_arm.spring_length = arm_length
	set_as_top_level(true)

func _append_target(node: Node3D):
	target_list.append(node)

func _erase_target(node: Node3D):
	target_list.erase(node)

func _search_target() -> Node3D:
	var closest_target: Node3D = null
	var closest_distance_2d := Global.LARGE_FLOAT
	for target: Node3D in target_list:
		if not is_instance_valid(target):
			continue
		if target.team_group == player.team_group:
			continue
		var target_position = target.get_lock_position()
		var distance := global_position.distance_to(target_position)
		if distance > lock_on_data.distance:
			continue
		eye_ray.target_position = eye_ray.to_local(target_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			continue
		var pos_2d = camera.unproject_position(target_position)
		if lock_on_data.region.has_point(pos_2d):
			var target_distance_2d = pos_2d.distance_to(lock_on_data.region.get_center())
			if target_distance_2d < closest_distance_2d:
				closest_target = target
				closest_distance_2d = target_distance_2d
	return closest_target

func _process(delta):
	if not camera.current:
		return
	spring_arm.rotation.x += input_direction.y * delta * invert_y
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_angle_x, max_angle_x)
	spring_arm.rotation.y += input_direction.x * delta * invert_x
	input_direction *= 0

func _physics_process(delta):
	if not camera.current:
		return
	var lerp_weight := 1.0 - pow(0.5, delta * 16.0)
	var new_pos = Vector3(player.position.x, position.y, player.position.z)
	position = position.lerp(new_pos, lerp_weight)
	var lerp_weight2 := 1.0 - pow(0.5, delta * 8.0)
	position.y = lerpf(position.y, player.position.y + height, lerp_weight2)
	
	eye_ray.global_position = camera.global_position
	var target = null
	if not manual_aim:
		target = _search_target()
	targeting.target = target
	if not target:
		eye_ray.target_position = -camera.global_basis.z * Global.LARGE_FLOAT
		var point = to_global(eye_ray.target_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			point = eye_ray.get_collision_point()
		targeting.position = point

func _unhandled_input(event):
	if not camera.current:
		return
	if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		input_direction = event.screen_relative * mouse_sensitivity
	elif event.is_action_pressed('manual_aim'):
		manual_aim = not manual_aim
