@tool
class_name LegIK3D extends SkeletonModifier3D

@onready var marker_right: Marker3D = $IKRightLeg
@onready var marker_left: Marker3D = $IKLeftLeg
@onready var ray_leg_base: RayCast3D = $RayCastLegBase
@onready var ray_right: RayCast3D = $RayCastR
@onready var ray_left: RayCast3D = $RayCastL
@onready var ik_mod: CCDIK3D = $'../CCDIK3D'

var leg_base_height := 0.0
var leg_base_bone := -1
var shin_r := -1
var shin_l := -1

func _ready():
	ik_mod.active = true
	setup()

func _process_modification_with_delta(delta):
	var skel = get_skeleton()
	ray_leg_base.position = skel.get_bone_global_pose(leg_base_bone).origin
	ray_right.transform = skel.get_bone_global_pose(shin_r)
	ray_left.transform = skel.get_bone_global_pose(shin_l)
	var leg_base_pose = skel.get_bone_global_pose(leg_base_bone)
	var weight = 10.0 * delta
	if ray_leg_base.is_colliding():
		var height = ray_leg_base.get_collision_point().y
		height -= skel.get_global_transform_interpolated().origin.y
		leg_base_height = move_toward(leg_base_height, height, weight)
	leg_base_pose.origin.y += leg_base_height
	skel.set_bone_global_pose(leg_base_bone, leg_base_pose)
	position_marker(ray_right, marker_right, 0)
	position_marker(ray_left, marker_left, 1)

func position_marker(ray: RayCast3D, marker: Marker3D, index: int) -> void:
	if ray.is_colliding():
		marker.position = ray.get_collision_point()
		marker.position.y += get_skeleton().get_bone_global_rest(get_skeleton().find_bone('Feet.L')).origin.y
		ik_mod.set_target_node(index, marker.get_path())
	else:
		ik_mod.set_target_node(index, ^'')

func setup() -> void:
	var skel = get_skeleton()
	leg_base_bone = skel.find_bone('LegBase')
	shin_r = skel.find_bone('Shin.R')
	shin_l = skel.find_bone('Shin.L')
	
	var id = skel.find_bone('Shin.L')
	var rest_y = skel.get_bone_global_rest(id).origin.y
	ray_left.target_position = Vector3(0.0, rest_y, 0.0)
	
	id = skel.find_bone('Shin.R')
	rest_y = skel.get_bone_global_rest(id).origin.y
	ray_right.target_position = Vector3(0.0, rest_y, 0.0)
	
	id = skel.find_bone('LegBase')
	rest_y = skel.get_bone_global_rest(id).origin.y
	ray_leg_base.target_position = Vector3(0.0, -rest_y, 0.0)
