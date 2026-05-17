class_name Bullet extends Node3D

@onready var ray_cast = $RayCast3D
@onready var timer = $Timer

@export var data: BulletData = null
@export var explosion_scene: PackedScene = null
@export var effect_scene: PackedScene = null
var damage_data: DamageData = null

func _ready():
	top_level = true
	timer.one_shot = true
	timer.timeout.connect(destroy)
	timer.start(data.life_time)

func _process(delta):
	var distance_delta: Vector3 = global_basis.z * data.speed * delta
	ray_cast.target_position = Vector3(0.0, 0.0, data.speed * delta)
	if ray_cast.is_colliding():
		var collision_point = ray_cast.get_collision_point()
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().current_scene.add_child(explosion)
			explosion.set_up(collision_point, damage_data)
		else:
			var collider = ray_cast.get_collider()
			if collider is Hitbox:
				collider.hit.emit(damage_data)
		if effect_scene:
			var effect = effect_scene.instantiate()
			get_tree().current_scene.add_child(effect)
			effect.set_up(collision_point, ray_cast.get_collision_normal())
		timer.stop()
		destroy()
	global_position += distance_delta

func set_up(spawn_point: Vector3, spawn_rotation: Vector3, _damage_data: DamageData, target_position: Vector3):
	global_position = spawn_point
	look_at(target_position, Vector3.UP, true)
	global_rotation += spawn_rotation
	damage_data = _damage_data

func destroy():
	queue_free()
