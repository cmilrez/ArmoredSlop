class_name Bullet extends Node3D

@onready var ray_cast = $RayCast3D
@onready var timer = $Timer

@export var data: BulletData = null
@export var hitspawn_scene: PackedScene = null
var damage_data: DamageData = null

func _ready():
	top_level = true
	timer.one_shot = true
	timer.timeout.connect(destroy)
	timer.start(data.life_time)

func _process(delta):
	var delta_speed = data.speed * delta
	global_position += basis.z * delta_speed
	ray_cast.target_position.z = delta_speed
	if ray_cast.is_colliding():
		if hitspawn_scene:
			var collision_point = ray_cast.get_collision_point()
			var node = hitspawn_scene.instantiate()
			get_tree().current_scene.add_child(node)
			if node is Explosion:
				node.set_up(collision_point, damage_data)
			elif node is VFXContainer:
				node.set_up(collision_point, ray_cast.get_collision_normal())
				var collider = ray_cast.get_collider()
				if collider is Hitbox:
					collider.hit.emit(damage_data)
		else:
			var collider = ray_cast.get_collider()
			if collider is Hitbox:
				collider.hit.emit(damage_data)
		timer.stop()
		destroy()

func set_up(spawn: Node3D, _damage_data: DamageData, target_position: Vector3):
	global_position = spawn.global_position
	look_at(target_position, Vector3.UP, true)
	global_rotation += spawn.rotation
	damage_data = _damage_data

func destroy():
	queue_free()
