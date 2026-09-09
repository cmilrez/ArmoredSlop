class_name Tracker3D extends Marker3D

signal target_changed

const SWITCH_TIME = 0.5

var lock_target := false
var target: Character3D = null: set=set_target
var tween: Tween
var blend := 1.0

func set_target(value):
	if lock_target and is_target_valid():
		return
	if not target == value:
		target = value
		target_changed.emit()
		if target:
			var diff = position - target.get_lock_position()
			var dist = diff.length()
			if dist > 100.0:
				position = target.get_lock_position() + (diff / dist) * 100.0
			blend = 0.0
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self, ^'blend', 1.0, SWITCH_TIME)

func _ready():
	top_level = true

func _process(delta):
	if is_instance_valid(target):
		if not target.alive:
			target = null
			return
		if blend < 1.0:
			position = position.lerp(target.get_lock_position(), blend)
		else:
			position = target.get_lock_position()

func is_target_valid() -> bool:
	return is_instance_valid(target)
