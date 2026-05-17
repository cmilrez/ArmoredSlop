extends Node3D

@onready var hurtbox = $Hurtbox
@export var max_scale = 10.0
@export var start_scale = 1.0

func _ready():
	top_level = true
	scale = Vector3.ONE * start_scale

func set_up(spawn_point: Vector3, _damage_data: DamageData):
	global_position = spawn_point
	global_rotation.y = randf() * PI
	hurtbox.damage_data = _damage_data
	
	var tween = create_tween()
	tween.tween_property(self, 'scale', Vector3.ONE * max_scale, 0.5)
	tween.parallel().tween_property(self, 'global_rotation:y', global_rotation.y + PI, 0.5)
	await tween.finished
	queue_free()
