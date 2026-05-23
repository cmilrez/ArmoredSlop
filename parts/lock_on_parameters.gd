class_name LockOnParamenters extends Resource

@export_range(0.0, 500.0, 0.001, 'or_greater', 'suffix:m') var max_distance := 150.0
@export var aim_rect := Rect2(Vector2.ZERO, Vector2.ONE):
	set(value):
		aim_rect = value
		emit_changed()
@export var aim_rect_offset := Vector2.ZERO:
	set(value):
		aim_rect_offset = value
		emit_changed()
