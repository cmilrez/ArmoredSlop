class_name Tracker3D extends Marker3D

signal target_changed

var lock_target := false
var target: Character3D = null:
	set(value):
		if not lock_target:
			var _emit_signal = not target == value
			target = value
			if _emit_signal:
				target_changed.emit()

func _ready():
	top_level = true

func _physics_process(delta):
	if is_instance_valid(target):
		if not target.alive:
			target = null
			return
		var weight = exp(-16.0 * delta)
		position = target.get_lock_position().lerp(position, weight)

func is_target_valid() -> bool:
	return is_instance_valid(target)
