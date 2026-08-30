@icon('res://addons/at-icons/node3d/missile.svg')
class_name Missile3D extends Projectile3D

signal started_homing

@onready var tracker: Tracker3D = $Tracker3D

@export var data: MissileData = null
var speed_curve_offset := 0.0
var homing := true:
	set(value):
		var emit = not homing and value
		homing = value
		if emit:
			started_homing.emit()

func _ready():
	if data.speed_curve_duration > 0.0:
		create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).tween_property(self, 'speed_curve_offset', 1.0, data.speed_curve_duration)
	if data.homing_delay > 0.0:
		homing = false
		create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).tween_property(self, 'homing', true, data.homing_delay)
	super._ready()

func move_and_collide(speed: float) -> bool:
	if data.speed_curve and speed_curve_offset < 1.0:
		speed *= data.speed_curve.sample(speed_curve_offset)
	return super.move_and_collide(speed)

func rotate_to_target() -> void:
	if homing:
		var target_pos = tracker.position
		var direction = -position.direction_to(target_pos)
		var cross = direction.cross(basis.z).normalized()
		var angle = direction.signed_angle_to(basis.z, cross)
		global_rotate(cross, signf(angle) * minf(absf(angle), data.turning_speed * get_physics_process_delta_time()))

func set_up(spawn: Node3D, dmg_data: DamageData, target_pos: Vector3, _target: Character3D = null) -> void:
	global_transform = spawn.global_transform
	damage_data = dmg_data
	tracker.position = target_pos
	tracker.target = _target
