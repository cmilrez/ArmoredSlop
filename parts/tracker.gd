class_name Tracker extends Marker3D

var lock_target := false
var target: Character = null:
	set(value):
		if not lock_target:
			target = value

func _ready():
	top_level = true

func _process(delta):
	if is_instance_valid(target):
		if not target.alive:
			target = null
			return
		position = target.get_lock_position()

func is_target_valid() -> bool:
	return is_instance_valid(target)
