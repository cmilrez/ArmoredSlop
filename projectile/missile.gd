class_name Missile extends Node3D

@onready var ray_cast = $RayCast3D
@onready var targeting = $Targeting
@onready var timer = $Timer

@export var data: MissileData = null
var damage_data: DamageData = null
var speed_curve_offset := 0.0
var homing := true

func _ready():
	if data.speed_curve_duration > 0.0:
		create_tween().tween_property(self, 'speed_curve_offset', 1.0, data.speed_curve_duration)
	if data.homing_delay > 0.0:
		homing = false
		create_tween().tween_property(self, 'homing', true, data.homing_delay)
	timer.one_shot = true
	timer.timeout.connect(detonate)
	timer.start(data.life_time)

func _process(delta):
	if homing:
		var target_position = targeting.get_targeting_position(data.speed, global_position)
		var direction: Vector3 = -global_position.direction_to(target_position)
		var cross = direction.cross(global_basis.z).normalized()
		var angle = direction.signed_angle_to(global_basis.z, cross)
		global_rotate(cross, signf(angle) * minf(absf(angle), data.turning_speed * delta))
	var speed = data.speed
	if data.speed_curve and speed_curve_offset < 1.0:
		speed *= data.speed_curve.sample(speed_curve_offset)
	var distance_delta: Vector3 = global_basis.z * speed * delta
	global_position += distance_delta
	ray_cast.target_position = Vector3(0.0, 0.0, speed * delta)
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider is Hitbox:
			collider.hit.emit(damage_data)
		timer.stop()
		detonate()

func set_up(spawn_transform: Transform3D, _damage_data: DamageData, target_position: Vector3, target: Character = null):
	global_transform = spawn_transform
	damage_data = _damage_data
	targeting.global_position = target_position
	targeting.target = target
	top_level = true

func detonate():
	queue_free()
