@tool
extends EditorScript

var path := 'res://parts/test/'

func _run():
	for file in ResourceLoader.list_directory(path):
		if not file.ends_with('.tscn'):
			continue
		var data_path = path + file.get_slice('.', 0) + '_data.tres'
		if ResourceLoader.exists(data_path):
			continue
		var scene = ResourceLoader.load(path + file)
		var part = scene.instantiate()
		if not part is Weapon3D:
			continue
		var part_data = UnitData.new()
		part_data.parameters = part.param
		part_data.scene = scene
		var error = ResourceSaver.save(part_data, data_path)
		if error:
			push_warning('OOPS: ',  error_string(error), ' ', data_path)
