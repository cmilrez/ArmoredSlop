class_name ArmsData extends BodyPartData

@export var max_weight := 100.0
@export var recoil_damp := 1.0
@export_range(0.0, 10.0, 0.01, 'or_greater', 'suffix:s') var recoil_recovery := 1.0
@export var melee_dmg_boost := 1.0
