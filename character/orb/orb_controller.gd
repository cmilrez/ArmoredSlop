extends Node

enum {WANDER, CHASE, DEATH}

@onready var timer = $Timer

@export var character: Character = null
@export var anim_player: AnimationPlayer = null
var home_position := Vector3.ZERO
var move_direction := Vector3.ZERO
var speed := 20.0
var accel := 3.0
var state := WANDER:
	set(value):
		if not state == value:
			state = value
			match state:
				WANDER:
					anim_player.play_backwards(&'StartChase')
					anim_player.queue(&'Idle')
				CHASE:
					move_direction = Vector3.ZERO
					anim_player.play(&'StartChase')
					timer.start(1.0)

func _ready():
	set_deferred(&'home_position', character.global_position)

func _process(delta):
	if not character.alive:
		state = DEATH
		return
	if character.targeting.target:
		state = CHASE
	else:
		state = WANDER

func _physics_process(delta):
	match state:
		WANDER:
			accel = 5.0
			speed = 20.0
			var home_dist = character.hor_distance(home_position)
			var home_dir = character.hor_direction(home_position)
			if home_dist < 30.0:
				if home_dir:
					move_direction = -home_dir
				else:
					move_direction = character.global_basis.z
			elif home_dist > 35.0:
				move_direction = home_dir
			else:
				move_direction = home_dir.rotated(Vector3.UP, PI/2.0)
			var home_height = home_position.y - character.global_position.y
			if absf(home_height) > 0.2:
				character.velocity.y = signf(home_height) * speed
			else:
				character.velocity.y = 0.0
			var hor_vel = Vector2(character.velocity.z, character.velocity.x)
			if hor_vel:
				character.rotation.y = lerp_angle(character.rotation.y, hor_vel.angle(), accel * delta)
		CHASE:
			accel = 10.0
			var target_pos = character.targeting.global_position
			var dir = character.hor_direction(target_pos)
			character.rotation.y = Vector2(dir.z, dir.x).angle()
			if timer.is_stopped():
				speed = 30.0
				var dist = character.hor_distance(target_pos)
				if dist < 100.0:
					speed = 200.0
					move_direction = dir.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI/2.0)
					var height = target_pos.y + 3.0 - character.global_position.y
					if absf(height) > 1.0:
						character.velocity.y = signf(height) * 30.0
					else:
						character.velocity.y = 0.0
					timer.start(0.3)
					await timer.timeout
					if character.targeting.target:
						character.weapons[0].activate(character.targeting)
						move_direction = Vector3.ZERO
						character.velocity = Vector3.ZERO
						timer.start(maxf(1.0, 2.0 * randf()))
				else:
					move_direction = dir
		DEATH:
			move_direction = Vector3.ZERO
			character.lock_on_marker.hide()
			character.velocity.x = 0.0
			character.velocity.z = 0.0
			character.velocity += character.get_gravity() * delta * 6.0
	if move_direction.x or move_direction.z:
		character.accelerate(move_direction, speed, accel)
	else:
		character.velocity.x = 0.0
		character.velocity.z = 0.0
