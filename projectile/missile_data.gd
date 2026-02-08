class_name MissileData extends ProjectileData

@export_range(0.0, 360.0, 0.001, 'radians_as_degrees', 'suffix:º/s') var turning_speed := Global.QUARTER_PI
@export_range(0.0, 10.0, 0.0001, 'or_greater', 'suffix:s') var homing_delay := 0.0
@export_range(0.0, 10.0, 0.0001, 'or_greater', 'suffix:s') var speed_curve_duration := 0.0
@export var speed_curve: Curve = null
