extends Weapon

@export var spawners: Node3D = null
@export var shot_interval := 0.0
@export var projectile_scene: PackedScene = null
@export var damage_data: DamageData = null

func _ready():
	can_use = true

func activate(targeting: Targeting):
	if not can_use:
		return
	can_use = false
	for spawn in spawners.get_children():
		var new_projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(new_projectile)
		var target_position = targeting.get_targeting_position(new_projectile.data.speed, spawn.global_position)
		new_projectile.set_up(spawn, damage_data, target_position)
		if shot_interval:
			await get_tree().create_timer(shot_interval).timeout
	can_use = true

func reload(manual_reload := false):
	return
