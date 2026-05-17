extends Node3D

@onready var timer = $Timer
@export var life_time = 1.0

func _ready():
	show_effects()
	top_level = true
	timer.one_shot = true
	timer.timeout.connect(func(): queue_free())
	timer.start(life_time)

func show_effects():
	for child in get_children():
		if child is GPUParticles3D:
			child.restart()

func set_up(spawn_point: Vector3, normal: Vector3):
	global_position = spawn_point
	global_basis = Basis.looking_at(normal, normal.cross(basis.x).normalized(), true)
