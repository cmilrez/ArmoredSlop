extends Weapon3D

@export var spawners: Node3D = null
@export var shot_interval := 0.0
@export var projectile_scene: PackedScene = null
@export var damage_data: DamageData = null

func _ready():
	can_use = true
	damage_data = damage_data.duplicate()

func activate(targets: Array[Character], aim_position := Vector3.ZERO) -> void:
	if not can_use:
		return
	can_use = false
	for spawn in spawners.get_children():
		var new_projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(new_projectile)
		new_projectile.set_up(spawn, damage_data, targets[0].get_lock_position(), targets[0])
		if shot_interval:
			await get_tree().create_timer(shot_interval).timeout
	can_use = true

func set_dmg_source(path: NodePath) -> void:
	if damage_data:
		damage_data.source = path

func reload(manual_reload := false):
	return
