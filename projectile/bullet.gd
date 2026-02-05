class_name Bullet extends Node3D

@onready var ray_cast = $RayCast3D

@export var data: BulletData = null
var damage_data: DamageData = null

func _ready():
	$Timer.start(data.life_time)

func _process(delta):
	var distance_delta: Vector3 = global_basis.z * data.speed * delta
	global_position += distance_delta
	ray_cast.target_position = Vector3(0.0, 0.0, data.speed * delta)
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider is Hitbox:
			collider.hit.emit(damage_data)
		$MeshInstance3D.hide()
		$Timer.stop()
		queue_free()

func _on_timer_timeout():
	queue_free()
