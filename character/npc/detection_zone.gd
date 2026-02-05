class_name DetectionZone extends Area3D

@onready var collision_shape = $CollisionShape3D
@onready var eye_ray = $EyeRay
@onready var timer = $Timer
@onready var targeting = %Targeting

@export var data: NPCData = null
@export var skeleton: Skeleton3D = null
@export var head_bone := 'Head'

func _ready():
	input_ray_pickable = false
	collision_layer = 0
	collision_mask = 4 # layer 3
	collision_shape.shape.radius = data.distance_max
	timer.timeout.connect(_on_timer_timout)

func _process(delta):
	if is_instance_valid(targeting.target):
		var target_position: Vector3 = targeting.target.lock_on_marker.global_position
		if (data.distance_max * data.distance_max) < target_position.distance_squared_to(global_position):
			targeting.target = null
			return
		eye_ray.target_position = eye_ray.to_local(target_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			if timer.is_stopped():
				timer.start(data.atention_spam)
		else:
			timer.stop()
	else:
		targeting.target = get_target()

func get_target(check_fov := true) -> Character:
	for body in get_overlapping_bodies():
		if not body.is_in_group(Global.TEAM_C):
			if body.is_in_group(owner.team_group):
				continue
		if check_fov:
			var direction_to_body := body.global_position - global_position
			var facing_direction := Vector3.FORWARD
			if skeleton:
				var head_global_pose = skeleton.get_bone_global_pose(skeleton.find_bone(head_bone)) * skeleton.global_transform
				facing_direction = head_global_pose.basis.z
			else:
				facing_direction = global_basis.z
			if facing_direction.angle_to(direction_to_body) > data.fov:
				continue
		return body
	return null

func _on_timer_timout():
	targeting.target = null

func _deactivate():
	set_process(false)
	targeting.target = null
