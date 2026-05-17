class_name ProjectileWeaponData extends PartData

@export_range(0.0, 60.0, 0.0001, 'or_greater', 'suffix:s') var shot_interval := 0.0
@export_range(0.0, 60.0, 0.0001, 'or_greater', 'suffix:s') var multishot_interval := 0.0
@export_range(0.0, 60.0, 0.0001, 'or_greater', 'suffix:s') var reload_time := 0.0
@export_range(0, 100, 1, 'or_greater') var clip_size := 0
@export_range(0, 100, 1, 'or_greater') var ammo_max := 0
@export_range(0, 100, 1, 'or_greater') var ammo_cost := 0
#@export_range(0.0, 90.0, 0.01, 'radians_as_degrees') var spread := 0.0
@export var damage_data: DamageData = null
@export var projectile_scene: PackedScene = null
