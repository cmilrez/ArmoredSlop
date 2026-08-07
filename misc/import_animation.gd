@tool
extends EditorScenePostImport

const path = 'res://assets/'

func _post_import(scene):
	for child in scene.get_children():
		if child is AnimationPlayer:
			import_animations(child)
	return scene

func import_animations(anim_player: AnimationPlayer) -> void:
	var save_path = path + anim_player.get_parent().name + '/'
	var anim_lib = anim_player.get_animation_library('')
	for anim_name in anim_player.get_animation_list():
		var new_name = anim_name
		if anim_name.contains('_Biped'):
			new_name = new_name.trim_suffix('_Biped')
		elif anim_name.contains('_Reverse'):
			new_name = new_name.trim_suffix('_Reverse')
		elif anim_name.contains('_Tank'):
			new_name = new_name.trim_suffix('_Tank')
		elif anim_name.contains('_Quad'):
			new_name = new_name.trim_suffix('_Quad')
		
		var anim_save_path = save_path + new_name + '.res'
		var custom_tracks: Array[int] = []
		
		var disk_animation: Animation = null
		if ResourceLoader.exists(anim_save_path):
			disk_animation = ResourceLoader.load(anim_save_path)
			custom_tracks = get_custom_tracks(disk_animation)
		
		var imported_anim = anim_player.get_animation(anim_name)
		anim_lib.rename_animation(anim_name, new_name)
		
		for i in range(imported_anim.get_track_count()):
			var track_path = String(imported_anim.track_get_path(i))
			imported_anim.track_set_path(i, 'Skeleton3D:' + track_path.get_slice(':', 1))
		
		for id in custom_tracks:
			disk_animation.copy_track(id, imported_anim)
		
		var error = ResourceSaver.save(imported_anim, anim_save_path)
		if error:
			push_warning('OOPS: ', error_string(error), ', Path: ', anim_save_path)
		#else:
		#	print('Saved: ', anim_save_path)

func get_custom_tracks(anim: Animation) -> Array[int]:
	var tracks: Array[int] = []
	for i in range(anim.get_track_count()):
		if not anim.track_is_imported(i):
			tracks.append(i)
	return tracks
