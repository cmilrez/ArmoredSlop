@tool
extends EditorScenePostImport

#var regex = RegEx.create_from_string('_(Tank|Biped)')

func _post_import(scene):
	for child in scene.get_children():
		if child is AnimationPlayer:
			rename_track_paths(child)
	return scene

func rename_track_paths(anim_player: AnimationPlayer) -> void:
	print('+ ', anim_player.get_parent().name)
	for anim_name in anim_player.get_animation_list():
		var animation = anim_player.get_animation(anim_name)
		var count = animation.get_track_count()
		for i in range(count):
			var property = String(animation.track_get_path(i))
			animation.track_set_path(i, 'Skeleton3D:' + property.get_slice(':', 1))
			print(' - Before: ', property, ' - After: ', animation.track_get_path(i))
		var anim_lib = anim_player.get_animation_library('')
		if anim_name.contains('_Biped'):
			anim_lib.rename_animation(anim_name, anim_name.trim_suffix('_Biped'))
		if anim_name.contains('_Reverse'):
			anim_lib.rename_animation(anim_name, anim_name.trim_suffix('_Reverse'))
		if anim_name.contains('_Tank'):
			anim_lib.rename_animation(anim_name, anim_name.trim_suffix('_Tank'))
		if anim_name.contains('_Quad'):
			anim_lib.rename_animation(anim_name, anim_name.trim_suffix('_Quad'))
		
