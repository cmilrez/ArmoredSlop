class_name PlayerCamera extends Node3D

@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
@onready var eye_ray = $EyeRay
@onready var targeting = %Targeting
@onready var player: Player = owner

@export_group('Camera Parameters')
@export var mouse_sensitivity := 0.02
@export var invert_y := -1
@export var invert_x := -1
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var max_angle_x := PI / 2
@export_range(-90.0, 90.0, 0.1, 'radians_as_degrees') var min_angle_x := -PI / 2
@export var arm_length := 10.0
@export var height := 9.5
@export_group('Targeting Parameters')
@export var param: LockOnParamenters = null

var target_list: Array[Node3D]
var input_direction := Vector2.ZERO
var manual_aim := false

func _ready():
	SignalBus.enemy_entered_screen.connect(append_target)
	SignalBus.enemy_exited_screen.connect(erase_target)
	spring_arm.spring_length = arm_length
	set_as_top_level(true)

func append_target(node: Node3D):
	target_list.append(node)

func erase_target(node: Node3D):
	target_list.erase(node)

func get_target() -> Node3D:
	var closest_target: Node3D = null
	var closest_distance_2d := Global.LARGE_9
	for target: Node3D in target_list:
		if not is_instance_valid(target):
			continue
		if target.is_in_group(player.team_group):
			continue
		var enemy_position = target.lock_on_marker.global_position
		var distance := global_position.distance_to(enemy_position)
		if distance > param.max_distance:
			continue
		eye_ray.target_position = eye_ray.to_local(enemy_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			continue
		var pos_2d = camera.unproject_position(target.lock_on_marker.global_position)
		if param.aim_rect.has_point(pos_2d):
			var target_distance_2d = pos_2d.distance_to(param.aim_rect.get_center())
			if target_distance_2d < closest_distance_2d:
				closest_target = target
				closest_distance_2d = target_distance_2d
	return closest_target

func _process(delta):
	eye_ray.global_position = camera.global_position
	var target = null
	if not manual_aim:
		target = get_target()
	targeting.target = target
	if not target:
		eye_ray.target_position = -camera.global_basis.z * Global.LARGE_9
		var point = to_global(eye_ray.target_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			point = eye_ray.get_collision_point()
		targeting.global_position = point

func _physics_process(delta):
	if not camera.current:
		return
	var lerp_weight := 1.0 - pow(0.5, delta * 16)
	position = position.lerp(player.position, lerp_weight)
	position.y = player.position.y + height
	
	spring_arm.rotation.x += input_direction.y * delta * invert_y
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_angle_x, max_angle_x)
	spring_arm.rotation.y += input_direction.x * delta * invert_x
	input_direction *= 0

func _unhandled_input(event):
	if not camera.current:
		return
	if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		input_direction = event.screen_relative * mouse_sensitivity
	elif event.is_action_released('manual_aim'):
		manual_aim = not manual_aim
