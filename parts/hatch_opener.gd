@tool
class_name HatchOpener extends SkeletonModifier3D

#@export_tool_button('CacheBones', 'Bone') var button1 = cache_bones
@export var match_name := 'Hatch'
@export_range(0.0, 180.0, 0.001, 'or_greater', 'radians_as_degrees') var max_angle := PI
@export_range(0.0, 1.0, 0.001) var progress := 0.0
@export var _hatch_bones: Array[int] = []
var _step = 0.0

func _ready():
	cache_bones()

func cache_bones():
	_hatch_bones.clear()
	var skeleton = get_skeleton()
	for bone in skeleton.get_bone_count():
		if skeleton.get_bone_name(bone).contains(match_name):
			_hatch_bones.append(bone)
	_step = 1.0 / _hatch_bones.size()

func _process_modification_with_delta(delta):
	var skeleton := get_skeleton()
	var count = _hatch_bones.size()
	for i in range(count):
		var pose = skeleton.get_bone_pose(_hatch_bones[i])
		var ratio = float(i) / count
		var angle = max_angle * ((progress - ratio) / _step)
		angle = clampf(angle, 0.0, max_angle)
		var new_pose = pose.rotated_local(Vector3.MODEL_FRONT, angle)
		skeleton.set_bone_pose(_hatch_bones[i], new_pose)
