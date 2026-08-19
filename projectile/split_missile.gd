extends Missile

@onready var spawners: Node3D = $Spawners

@export_range(0.0, 100.0, 0.001, 'or_greater', 'suffix:m') var split_distance := 20.0
@export var missile_scene: PackedScene = null

func _physics_process(delta):
	var distance_sqr = position.distance_squared_to(tracker.position)
	if distance_sqr < split_distance * split_distance:
		if missile_scene:
			for spawn in spawners.get_children():
				var node: Missile = missile_scene.instantiate()
				get_tree().current_scene.add_child(node)
				node.set_up(spawn, damage_data, tracker.position, tracker.target)
		destroy()
	elif move_and_collide(data.speed):
		hitspawn_and_damage()
		destroy()
	else:
		rotate_to_target(false)
