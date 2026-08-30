@icon('res://addons/at-icons/node3d/bullet.svg')
class_name Bullet3D extends Projectile3D

@export var data: BulletData = null

func _physics_process(delta):
	if move_and_collide(data.speed):
		hitspawn_and_damage()
		destroy()

func set_up(spawn: Node3D, dmg_data: DamageData, target_pos: Vector3, _target: Character3D = null) -> void:
	global_position = spawn.global_position
	if _target:
		target_pos = get_prediction(data.speed, _target)
	look_at(target_pos, Vector3.UP, true)
	global_rotation += spawn.rotation
	damage_data = dmg_data
