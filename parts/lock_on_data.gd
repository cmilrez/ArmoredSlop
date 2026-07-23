class_name LockOnData extends PartData

@export var region := Rect2(0.0, 0.0, 400.0, 400.0):
	set(value):
		if not region == value:
			region = value
			emit_changed()
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var time := 1.0
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var missile_time := 1.0
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:m') var distance := 100.0
