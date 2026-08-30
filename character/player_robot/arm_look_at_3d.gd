@tool
class_name LookAtArm3D extends SkeletonModifier3D

const DURATION = 0.2 # sec

@export var target: Node3D = null
@export var shoulder_name := '':
	set(value):
		shoulder_name = value
		_update_bone(&'shoulder_bone', shoulder_name)
@export var arm_name := '':
	set(value):
		arm_name = value
		_update_bone(&'arm_bone', arm_name)
@export_range(0.0, 90.0, 0.01, 'radians_as_degrees') var shoulder_angle := Global.QUARTER_PI
@export_range(0.0, 90.0, 0.01, 'radians_as_degrees') var x_limit_angle := Global.QUARTER_PI
@export_range(0.0, 90.0, 0.01, 'radians_as_degrees') var z_limit_angle := Global.QUARTER_PI
var primary_rotation_axis := Vector3.RIGHT
var secondary_rotation_axis := Vector3.BACK
var shoulder_bone := -1
var arm_bone := -1
var tween: Tween = null
var on_off := false

func toggle(value: bool) -> void:
	if on_off == value:
		return
	on_off = value
	if tween:
		tween.kill()
	tween = create_tween()
	const PROPERTY = ^'influence'
	if value:
		tween.tween_property(self, PROPERTY, 1.0, DURATION)
	else:
		tween.tween_property(self, PROPERTY, 0.0, DURATION).set_delay(DURATION)

func _update_bone(property: StringName, bone_name: String) -> void:
	var skel = get_skeleton()
	if skel:
		set(property, skel.find_bone(bone_name))

func _validate_property(property: Dictionary):
	if property.name in ['shoulder_name', 'arm_name']:
		var skel = get_skeleton()
		if skel:
			property.hint = PROPERTY_HINT_ENUM_SUGGESTION
			property.hint_string = skel.get_concatenated_bone_names()
		else:
			property.hint = PROPERTY_HINT_NONE
			property.hint_string = ''

func _set(property, value):
	if property == &'influence':
		influence = value
		if is_zero_approx(influence):
			active = false
		else:
			active = true
		return true
	return false

func _ready():
	shoulder_name = shoulder_name
	arm_name = arm_name

func _process_modification_with_delta(delta):
	var skeleton = get_skeleton()
	# Rotate shoulder
	if not is_zero_approx(shoulder_angle):
		var shoulder_pose = skeleton.get_bone_pose(shoulder_bone)
		shoulder_pose = shoulder_pose.rotated(Vector3.LEFT, shoulder_angle)
		skeleton.set_bone_pose(shoulder_bone, shoulder_pose)
	# Counter shoulder rotation
	var arm_pose = skeleton.get_bone_rest(arm_bone)
	if not is_zero_approx(shoulder_angle):
		arm_pose = arm_pose.rotated_local(Vector3.LEFT, shoulder_angle)
	
	if target:
		var arm_space = skeleton.get_global_transform_interpolated() * skeleton.get_bone_global_pose(shoulder_bone)
		arm_space = arm_space.translated_local(arm_pose.origin)
		var target_vector = target.get_global_transform_interpolated().origin - arm_space.origin
		target_vector = (target_vector * arm_space.basis).normalized()
		arm_pose = _look_at_with_axes(arm_pose, target_vector)
	skeleton.set_bone_pose(arm_bone, arm_pose)

func _look_at_with_axes(p_rest: Transform3D, forward_vector: Vector3) -> Transform3D:
	# Primary rotation by projection to 2D plane by xform_inv and picking elements.
	var current_vector = p_rest.basis.y.normalized()
	var src_vec2 = _get_projection_vector(forward_vector * p_rest.basis, primary_rotation_axis).normalized()
	var dst_vec2 = _get_projection_vector(current_vector * p_rest.basis, primary_rotation_axis).normalized()
	var calculated_angle = src_vec2.angle_to(dst_vec2)
	var primary_result = p_rest.rotated_local(primary_rotation_axis, calculated_angle)
	
	calculated_angle = clampf(calculated_angle, -x_limit_angle, x_limit_angle)
	var current_result = p_rest.rotated_local(primary_rotation_axis, calculated_angle)
	
	# Secondary rotation by projection to 2D plane by xform_inv and picking elements.
	current_vector = primary_result.basis.y.normalized()
	src_vec2 = _get_projection_vector(forward_vector * primary_result.basis, secondary_rotation_axis).normalized()
	dst_vec2 = _get_projection_vector(current_vector * primary_result.basis, secondary_rotation_axis).normalized()
	calculated_angle = src_vec2.angle_to(dst_vec2)
	
	calculated_angle = clampf(calculated_angle, -z_limit_angle, z_limit_angle)
	current_result = current_result.rotated_local(secondary_rotation_axis, calculated_angle)
	
	return current_result

func _get_projection_vector(vector: Vector3, axis: Vector3) -> Vector2:
	# NOTE: axis is swapped between 2D and 3D.
	var ret: Vector2
	match axis:
		Vector3.RIGHT:
			ret = Vector2(vector.z, vector.y)
		#Vector3.UP:
			#ret = Vector2(vector.x, vector.z)
		Vector3.BACK:
			ret = Vector2(vector.y, vector.x)
	return ret
