@tool
class_name DetectionZone extends Area3D

@onready var eye_ray: RayCast3D = $EyeRay
@onready var timer: Timer = $Timer
@onready var tracker: Tracker3D = %Tracker3D
@onready var character: Character3D = get_parent()

@export var data: NPCData = null
@export var skeleton: Skeleton3D = null
@export var head_bone := 'Head':
	set(value):
		head_bone = value
		if skeleton:
			bone_id = skeleton.find_bone(head_bone)
var bone_id := -1
var target_ctx: TargetContext = null

func _validate_property(property: Dictionary):
	if property.name == 'head_bone':
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM_SUGGESTION
			property.hint_string = skeleton.get_concatenated_bone_names()
		else:
			property.hint = PROPERTY_HINT_NONE
			property.hint_string = ''

func _ready():
	collision_layer = 0
	collision_mask = 20 # layer 3, 5
	$CollisionShape3D.shape.radius = data.distance_max
	if Engine.is_editor_hint():
		return
	head_bone = head_bone
	target_ctx = character.target_ctx
	target_ctx.tracker = tracker
	timer.timeout.connect(_on_timer_timout)

func _process(delta):
	if Engine.is_editor_hint():
		return
	if tracker.target:
		var target_position = tracker.position
		if (data.distance_max * data.distance_max) < target_position.distance_squared_to(character.get_lock_position()):
			set_target(null)
			return
		eye_ray.target_position = eye_ray.to_local(target_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			if timer.is_stopped():
				timer.start(data.atention_spam)
		else:
			timer.stop()
	else:
		set_target(_search_target())

func set_target(target: Character3D) -> void:
	tracker.target = target
	if target:
		target_ctx.list.resize(1)
		target_ctx.list[0] = tracker.target
		target_ctx.index = 0
	else:
		target_ctx.list.clear()
		target_ctx.index = -1

func _search_target() -> Character3D:
	for body in get_overlapping_bodies():
		if character.is_same_team(body.team):
			continue
		if not body.alive:
			continue
		eye_ray.target_position = eye_ray.to_local(body.get_lock_position())
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			continue
		var target_direction = body.global_position - global_position
		var facing_direction: Vector3
		if skeleton:
			var head_global_pose = skeleton.get_bone_global_pose(bone_id) * skeleton.get_global_transform_interpolated() 
			facing_direction = head_global_pose.basis.z
		else:
			facing_direction = global_basis.z
		if facing_direction.angle_to(target_direction) > data.fov:
			continue
		return body
	return null

func set_target_from_damage(dmg_data: DamageData):
	var source = get_node_or_null(dmg_data.source)
	if source:
		if get_parent().is_same_team(source.team):
			return
		set_target(source)

func deactivate():
	process_mode = Node.PROCESS_MODE_DISABLED
	set_target(null)

func _on_timer_timout():
	set_target(null)
