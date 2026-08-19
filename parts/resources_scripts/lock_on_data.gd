class_name LockOnData extends PartData

@export var region := Rect2(0.0, 0.0, 400.0, 400.0):
	set(value):
		if not region == value:
			region = value
			emit_changed()
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var single_duration := 0.5
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var multi_duration := 0.25
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:m') var distance := 200.0
