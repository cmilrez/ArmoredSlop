@tool
class_name ArmRecoil3D extends SkeletonModifier3D

enum Arm {RIGHT_ARM, LEFT_ARM}
const DURATION = 0.2 # sec

@export var side: Arm = Arm.RIGHT_ARM
@export var shoulder_name := '':
	set(value):
		shoulder_name = value
		_update_bone(&'shoulder_bone', shoulder_name)
@export var arm_name := '':
	set(value):
		arm_name = value
		_update_bone(&'arm_bone', arm_name)
@export_tool_button('Test', 'MainPlay') var button1 = activate
var shoulder_bone := -1
var arm_bone := -1
var rand_angle := 0.0
var tween: Tween = null

func activate() -> void:
	influence = 1.0
	rand_angle = randf_range(0.5, 1.0) * PI * 0.20
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'influence', 0.0, DURATION).set_ease(Tween.EASE_IN)

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
	var skel = get_skeleton()
	
	var shoulder_pose = skel.get_bone_pose(shoulder_bone)
	shoulder_pose = shoulder_pose.rotated(Vector3.RIGHT, rand_angle)
	skel.set_bone_pose(shoulder_bone, shoulder_pose)
	
	var arm_pose = skel.get_bone_pose(arm_bone)
	arm_pose = arm_pose.rotated_local(Vector3.RIGHT, 1.5 * rand_angle)
	skel.set_bone_pose(arm_bone, arm_pose)

func _on_builder_weapons_built(nodes):
	var wp = nodes[side]
	if wp is ProjectileWeapon3D:
		wp.shot_fired.connect(activate)
