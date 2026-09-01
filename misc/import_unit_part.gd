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
		var param: Resource
		match unit_type:
			'melee':      param = MeleeWeaponParam.new()
			'projectile': param = ProjectileWeaponParam.new()
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

func update_scene(_path: String, _node: Node3D) -> void:
	#var _scene = ResourceLoader.load(_path)
	return

func create_scene(_path: String, _node: Node3D) -> void:
	set_children_owner(_node, _node)
	var anim_player = AnimationPlayer.new()
	var timer = Timer.new()
	_node.add_child(anim_player)
	_node.move_child(anim_player, 0)
	anim_player.add_sibling(timer)
	anim_player.name = 'AnimationPlayer'
	anim_player.owner = _node
	timer.name = 'Timer'
	timer.owner = _node
	var new_scene = PackedScene.new()
	new_scene.pack(_node)
	ResourceSaver.save(new_scene, _path)

func get_unit_slot(slot_str: String) -> UnitData.Slot:
	var slot: UnitData.Slot
	match slot_str:
		'hand':     slot = UnitData.Slot.HAND
		'arm':      slot = UnitData.Slot.ARM
		'back':     slot = UnitData.Slot.BACK
		'shoulder': slot = UnitData.Slot.SHOULDER
	return slot

func set_children_owner(owner: Node, node: Node):
	for child in node.get_children():
		child.owner = owner
		set_children_owner(owner, child)
