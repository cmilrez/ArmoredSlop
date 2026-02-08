class_name Bullet extends Node3D

@onready var ray_cast = $RayCast3D
@onready var timer = $Timer

@export var data: BulletData = null
var damage_data: DamageData = null

func _ready():
	timer.timeout.connect(destroy)
	timer.start(data.life_time)

func _process(delta):
	var distance_delta: Vector3 = global_basis.z * data.speed * delta
	global_position += distance_delta
	ray_cast.target_position = Vector3(0.0, 0.0, data.speed * delta)
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider is Hitbox:
			collider.hit.emit(damage_data)
		timer.stop()
		destroy()

func set_up(spawn_transform: Transform3D, _damage_data: DamageData, target_position: Vector3):
	global_transform = spawn_transform
	damage_data = _damage_data
	look_at(target_position, Vector3.UP, true)
	top_level = true

func destroy():
	queue_free()
