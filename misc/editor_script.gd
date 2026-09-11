@tool
extends EditorScript

const PATH1 = 'res://parts/test/'
const PATH2 = 'res://misc/biped_robot_skeleton_profile.tres'
const PATH3 = 'res://misc/biped_robot_bone_map.tres'

func _run():
	#extract_data_from_scene()
	#create_unit_data()
	extract_skel_profile()
	setup_bone_map()
	pass

func extract_data_from_scene():
	for file in ResourceLoader.list_directory(PATH1):
		if not (file.ends_with('.tscn') or file.ends_with('.scn')):
			continue
		var node = ResourceLoader.load(PATH1 + file).instantiate()
		var data = node.get(&'data')
		if not data:
			continue
		var data_path = PATH1 + file.get_slice('.', 0) + '_data.tres'
		if ResourceLoader.exists(data_path):
			continue
		var error = ResourceSaver.save(data, data_path)
		if error:
			push_warning('OOPS: ', error_string(error), ' ', file)

func create_unit_data():
	for file in ResourceLoader.list_directory(PATH1):
		if not file.ends_with('.tscn'):
			continue
		var data_path = PATH1 + file.get_slice('.', 0) + '_data.tres'
		if ResourceLoader.exists(data_path):
			continue
		var scene = ResourceLoader.load(PATH1 + file)
		var part = scene.instantiate()
		if not part is Weapon3D:
			continue
		var part_data = UnitData.new()
		part_data.parameters = part.param
		part_data.scene = scene
		var error = ResourceSaver.save(part_data, data_path)
		if error:
			push_warning('OOPS: ',  error_string(error), ' ', data_path)

func extract_skel_profile():
	var skel: Skeleton3D = EditorInterface.get_edited_scene_root().find_child('Skeleton3D')
	var profile: SkeletonProfile = ResourceLoader.load(PATH2)
	if not (PATH2 and skel and profile):
		return
	var bone_count = skel.get_bone_count()
	profile.bone_size = bone_count
	
	var topmost = 0.0
	var bottommost = 0.0
	var leftmost = 0.0
	var rightmost = 0.0
	for id in range(bone_count):
		var rest_pos = skel.get_bone_global_rest(id).origin
		if rest_pos.x < leftmost:
			leftmost = rest_pos.x
		if rest_pos.x > rightmost:
			rightmost = rest_pos.x
		if rest_pos.y > bottommost:
			bottommost = rest_pos.y
		if rest_pos.y < topmost:
			topmost = rest_pos.y
	
	var limit_x = absf(leftmost) + absf(rightmost) + 3.0
	var limit_y = absf(topmost) + absf(bottommost) + 3.0
	
	for id in range(bone_count):
		profile.set_bone_name(id, skel.get_bone_name(id))
		var parent = skel.get_bone_parent(id)
		if parent > 0:
			profile.set_bone_parent(id, skel.get_bone_name(parent))
		profile.set_tail_direction(id, SkeletonProfile.TAIL_DIRECTION_END)
		profile.set_reference_pose(id, skel.get_bone_rest(id))
		profile.set_group(id, 'Body')
		var rest_pos = skel.get_bone_global_rest(id).origin
		var handle = Vector2(rest_pos.x / limit_x, rest_pos.y / limit_y)
		handle.x = minf(1.0, 0.5 + handle.x)
		handle.y = maxf(0.0, 1.0 - handle.y)
		profile.set_handle_offset(id, handle)
		#profile.

func setup_bone_map():
	var skel: Skeleton3D = EditorInterface.get_edited_scene_root().find_child('Skeleton3D')
	var profile: SkeletonProfile = ResourceLoader.load(PATH2)
	var bmap: BoneMap = ResourceLoader.load(PATH3)
	if not (PATH3 and bmap and skel and profile):
		return
	bmap.profile = profile
	for id in range(skel.get_bone_count()):
		var skel_bone_name = skel.get_bone_name(id)
		var prof_bone_name = profile.get_bone_name(id)
		bmap.set_skeleton_bone_name(prof_bone_name, skel_bone_name)
