class_name BoosterData extends PartData

@export var power := 10.0
@export var energy_drain := 1.0

@export var upward_power := 10.0
@export var upward_energy_drain := 1.0

@export var dash_power := 20.0
@export var dash_energy_drain := 1.0
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var dash_duration := 0.5
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var dash_cooldown := 1.0

@export var superboost_power := 20.0
@export var superboost_energy_drain := 1.0
