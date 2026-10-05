@tool
class_name LegIK3D extends SkeletonModifier3D

@onready var marker_right: Marker3D = $IKRightLeg
@onready var marker_left: Marker3D = $IKLeftLeg
@onready var ray_leg_base: RayCast3D = $RayCastLegBase
@onready var ray_right: RayCast3D = $RayCastR
@onready var ray_left: RayCast3D = $RayCastL
@onready var ik_mod: CCDIK3D = $'../CCDIK3D'

var feet_rest_height := 0.0
var leg_base_height := 0.0
var leg_base_bone := -1
var shin_r_bone := -1
var shin_l_bone := -1

func _ready():
	setup()

func _process_modification_with_delta(delta):
	var skel = get_skeleton()
	ray_leg_base.position = skel.get_bone_global_pose(leg_base_bone).origin
	var leg_base_pose = skel.get_bone_global_pose(leg_base_bone)
	if ray_leg_base.is_colliding():
		var weight = 10.0 * delta
		var height = ray_leg_base.get_collision_point().y
		height -= skel.get_global_transform_interpolated().origin.y
		leg_base_height = move_toward(leg_base_height, height, weight)
	leg_base_pose.origin.y += leg_base_height - 0.5
	skel.set_bone_global_pose(leg_base_bone, leg_base_pose)
	ray_right.transform = skel.get_bone_global_pose(shin_r_bone)
	ray_left.transform = skel.get_bone_global_pose(shin_l_bone)
	position_marker(ray_right, marker_right, 0)
	position_marker(ray_left, marker_left, 1)

func position_marker(ray: RayCast3D, marker: Marker3D, index: int) -> void:
	if ray.is_colliding():
		marker.position = ray.get_collision_point()
		marker.position.y += feet_rest_height
		ik_mod.set_target_node(index, marker.get_path())
	else:
		ik_mod.set_target_node(index, ^'')

func setup() -> void:
	var skel = get_skeleton()
	leg_base_bone = skel.find_bone('LegBase')
	shin_r_bone = skel.find_bone('Shin.R')
	shin_l_bone = skel.find_bone('Shin.L')
	feet_rest_height = skel.get_bone_global_rest(skel.find_bone('Feet.R')).origin.y
	
	var id = skel.find_bone('Shin.L')
	var rest_y = skel.get_bone_global_rest(id).origin.y
	ray_left.target_position = Vector3(0.0, rest_y, 0.0)
	
	id = skel.find_bone('Shin.R')
	rest_y = skel.get_bone_global_rest(id).origin.y
	ray_right.target_position = Vector3(0.0, rest_y, 0.0)
	
	id = skel.find_bone('LegBase')
	rest_y = skel.get_bone_global_rest(id).origin.y
	ray_leg_base.target_position = Vector3(0.0, -rest_y, 0.0)
	
	ik_mod.active = true
	ik_mod.setting_count = 2
	ik_mod.set_root_bone_name(0, 'Thigh.R')
	ik_mod.set_root_bone_name(1, 'Thigh.L')
	ik_mod.set_end_bone_name(0, 'Feet.R')
	ik_mod.set_end_bone_name(1, 'Feet.L')
	var joint_limit = JointLimitationCone3D.new()
	joint_limit.angle = deg_to_rad(180.0)
	ik_mod.set_joint_limitation(0, 0, joint_limit)
	ik_mod.set_joint_limitation(1, 0, joint_limit)
	joint_limit = JointLimitationCone3D.new()
	joint_limit.angle = deg_to_rad(120.0)
	ik_mod.set_joint_limitation(0, 1, joint_limit)
	ik_mod.set_joint_limitation(1, 1, joint_limit)
	var quat = Quaternion(Vector3.RIGHT, deg_to_rad(-60))
	ik_mod.set_joint_limitation_rotation_offset(0, 1, quat)
	ik_mod.set_joint_limitation_rotation_offset(1, 1, quat)
	ik_mod.set_joint_rotation_axis(0, 1, SkeletonModifier3D.ROTATION_AXIS_X)
	ik_mod.set_joint_rotation_axis(1, 1, SkeletonModifier3D.ROTATION_AXIS_X)
