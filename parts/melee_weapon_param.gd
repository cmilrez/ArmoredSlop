class_name MeleeWeaponParam extends Resource

@export_range(0.0, 60.0, 0.0001, 'or_greater', 'suffix:s') var reload_time := 0.0
@export_range(0.0, 100.0, 1.0, 'or_greater', 'hide_control') var bullet_damage := 0.0
@export_range(0.0, 100.0, 1.0, 'or_greater', 'hide_control') var energy_damage := 0.0
@export_range(0.0, 100.0, 1.0, 'or_greater', 'hide_control') var explosive_damage := 0.0
