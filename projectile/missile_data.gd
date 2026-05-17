class_name MissileData extends Resource

@export_range(0.001, 60.0, 0.001, 'or_greater', 'suffix:s') var life_time := 10.0
@export_range(0.001, 1000.0, 0.001, 'or_greater', 'suffix:m/s') var speed := 180.0
@export_range(0.0, 360.0, 0.001, 'radians_as_degrees', 'suffix:º/s') var turning_speed := PI
@export_range(0.0, 10.0, 0.0001, 'or_greater', 'suffix:s') var homing_delay := 0.0
@export_range(0.0, 10.0, 0.0001, 'or_greater', 'suffix:s') var speed_curve_duration := 0.0
@export var speed_curve: Curve = null
