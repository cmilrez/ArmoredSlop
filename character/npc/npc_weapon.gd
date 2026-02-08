extends Node

@onready var timer = $Timer

@export var spawners: Node3D = null
@export var damage_data: DamageData = null
@export var projectile_scene: PackedScene = null
@export var shot_interval := 0.0

func activate(targeting: Targeting):
	for spawn: Node3D in spawners.get_children():
		var new_projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(new_projectile)
		var target_position = targeting.get_targeting_position(new_projectile.data.speed, spawn.global_position)
		new_projectile.set_up(spawn.global_transform, damage_data, target_position)
		if shot_interval:
			timer.start(shot_interval)
			await timer.timeout
