@tool
extends EditorScript

var path := &'res://parts/test/'

func _run():
	for file in ResourceLoader.list_directory(path):
		if not (file.ends_with('.tscn') or file.ends_with('.scn')):
			continue
		var node = ResourceLoader.load(path + file).instantiate()
		var data = node.get(&'data')
		if not data:
			continue
		var data_path = path + file.get_slice('.', 0) + '_data.tres'
		if ResourceLoader.exists(data_path):
			continue
		var error = ResourceSaver.save(data, data_path)
		if error:
			push_warning('OOPS: ', error_string(error), ' ', file)
