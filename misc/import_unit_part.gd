@tool
extends EditorScenePostImport

var path := &'res://parts/test/'

func _post_import(scene):
	for node in scene.get_children():
		iterate(node)
	return scene

func iterate(node: Node) -> void:
	if node == null:
		return
	
	var split_name = node.name.split('-')
	node.name = split_name[-1]
	var name = split_name[-1].to_snake_case()
	var unit_type = split_name[1]
	
	var param_path = path + name + '_param.tres'
	var scene_path = path + name + '.tscn'
	var data_path = path + name + '_data.tres'

	var data: UnitData
	
	if not ResourceLoader.exists(param_path):
		var param = WeaponParam.new()
		ResourceSaver.save(param, param_path)
	
	if ResourceLoader.exists(scene_path):
		update_scene(scene_path, node)
	else:
		create_scene(scene_path, node)
	
	if ResourceLoader.exists(data_path):
		data = ResourceLoader.load(data_path)
	else:
		data = UnitData.new()
	
	data.slot = get_unit_slot(split_name[0])
	data.parameters = ResourceLoader.load(param_path)
	data.scene = ResourceLoader.load(scene_path)
	ResourceSaver.save(data, data_path)

func update_scene(_path: String, node: Node3D) -> void:
	var scene_node = ResourceLoader.load(_path).instantiate()
	var node_skel = node.find_child('Skeleton3D')
	var scene_skel = scene_node.find_child('Skeleton3D')
	if node_skel and scene_skel:
		copy_skeleton(node_skel, scene_skel)
	var new_scene = PackedScene.new()
	new_scene.pack(scene_node)
	ResourceSaver.save(new_scene, _path)

func copy_skeleton(source: Skeleton3D, target: Skeleton3D) -> void:
	target.clear_bones()
	for bone in range(source.get_bone_count()):
		var name = source.get_bone_name(bone)
		var rest = source.get_bone_rest(bone)
		target.add_bone(name)
		target.set_bone_rest(bone, rest)
	for bone in range(source.get_bone_count()):
		var parent_bone = source.get_bone_parent(bone)
		if parent_bone > -1:
			target.set_bone_parent(bone, parent_bone)
	target.reset_bone_poses()

func create_scene(_path: String, node: Node3D) -> void:
	setup_children(node, node)
	var anim_player = AnimationPlayer.new()
	var timer = Timer.new()
	node.add_child(anim_player)
	node.move_child(anim_player, 0)
	anim_player.add_sibling(timer)
	anim_player.name = 'AnimationPlayer'
	anim_player.owner = node
	timer.name = 'Timer'
	timer.owner = node
	var new_scene = PackedScene.new()
	new_scene.pack(node)
	ResourceSaver.save(new_scene, _path)

func setup_children(owner: Node, node: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child is VisualInstance3D:
			child.layers = 4
		setup_children(owner, child)

func get_unit_slot(slot_str: String) -> UnitData.Slot:
	var slot: UnitData.Slot
	match slot_str:
		'hand':     slot = UnitData.Slot.HAND
		'arm':      slot = UnitData.Slot.ARM
		'back':     slot = UnitData.Slot.BACK
		'shoulder': slot = UnitData.Slot.SHOULDER
	return slot
