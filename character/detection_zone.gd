@tool
class_name DetectionZone extends Area3D

@onready var eye_ray: RayCast3D = $EyeRay
@onready var timer: Timer = $Timer
@onready var tracker: Tracker = %Tracker

@export var data: NPCData = null
@export var skeleton: Skeleton3D = null
@export var head_bone := 'Head':
	set(value):
		head_bone = value
		if skeleton:
			bone_id = skeleton.find_bone(head_bone)
var character: Character = null
var bone_id := -1

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
	character = get_parent()
	head_bone = head_bone
	timer.timeout.connect(_on_timer_timout)

func _process(delta):
	if Engine.is_editor_hint():
		return
	if tracker.is_target_valid():
		var target_position = tracker.position
		if (data.distance_max * data.distance_max) < target_position.distance_squared_to(character.get_lock_position()):
			tracker.target = null
			return
		eye_ray.target_position = eye_ray.to_local(target_position)
		eye_ray.force_raycast_update()
		if eye_ray.is_colliding():
			if timer.is_stopped():
				timer.start(data.atention_spam)
		else:
			timer.stop()
	else:
		tracker.target = search_target()

func search_target() -> Character:
	for body in get_overlapping_bodies():
		if character.is_same_team(body.team):
			continue
		#if body == parent: # same team does it
			#continue
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
		tracker.target = source

func deactivate():
	process_mode = Node.PROCESS_MODE_DISABLED
	tracker.target = null

func _on_timer_timout():
	tracker.target = null
