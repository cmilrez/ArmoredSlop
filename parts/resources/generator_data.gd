class_name GeneratorData extends PartData

@export var max_charge := 100.0
@export var energy_capacity := 100.0
@export var recharge_rate := 10.0
@export var recovery_charge := 40.0
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var recovery_time := 5.0
