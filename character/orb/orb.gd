extends NPC

enum {WANDER, CHASE, DEATH}

@onready var timer = $Timer

@export var anim_player: AnimationPlayer = null
var home_position := Vector3.ZERO
var accel := 10.0
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
				DEATH:
					anim_player.play(&'Death')

func _ready():
	super._ready()
	set_deferred(&'home_position', global_position)

func _process(delta):
	if not alive:
		state = DEATH
		return
	if tracker.is_target_valid():
		state = CHASE
	else:
		state = WANDER

func _physics_process(delta):
	match state:
		WANDER:
			accel = 10.0
			speed = 20.0
			var home_dist = hor_distance(home_position)
			var home_dir = hor_direction(home_position)
			if home_dist < 30.0:
				if home_dir:
					move_direction = -home_dir
				else:
					move_direction = global_basis.z
			elif home_dist > 35.0:
				move_direction = home_dir
			else:
				move_direction = home_dir.rotated(Vector3.UP, PI/2.0)
			var home_height = home_position.y - global_position.y
			if absf(home_height) > 0.2:
				velocity.y = signf(home_height) * speed
			else:
				velocity.y = 0.0
			var hor_vel = Vector2(velocity.z, velocity.x)
			if hor_vel:
				rotation.y = lerp_angle(rotation.y, hor_vel.angle(), accel * delta)
		CHASE:
			accel = 10.0
			var target_pos = tracker.global_position
			var dir = hor_direction(target_pos)
			rotation.y = Vector2(dir.z, dir.x).angle()
			if timer.is_stopped():
				var dist = hor_distance(target_pos)
				if dist < 100.0:
					speed = 200.0
					move_direction = dir.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI/2.0)
					var height = target_pos.y + 3.0 - global_position.y
					if absf(height) > 1.0:
						velocity.y = signf(height) * 30.0
					else:
						velocity.y = 0.0
					timer.start(0.3)
					await timer.timeout
					if tracker.is_target_valid():
						weapons[0].activate([tracker.target])
						move_direction = Vector3.ZERO
						velocity = Vector3.ZERO
						timer.start(maxf(1.0, 2.0 * randf()))
				else:
					speed = 30.0
					move_direction = dir
		DEATH:
			move_direction = Vector3.ZERO
			lock_on_marker.hide()
			velocity.x = 0.0
			velocity.z = 0.0
			velocity += get_gravity() * delta * 6.0
	if move_direction.x or move_direction.z:
		accelerate(move_direction, speed, accel)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	do_friction(2.0)
	move_and_slide()
