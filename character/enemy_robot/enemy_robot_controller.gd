extends Node

enum {WANDER, CHASE, DEATH}

@onready var timer = $Timer

@export var character: Character = null
@export var anim_tree: AnimationTree = null
var home_position := Vector3.ZERO
var state := WANDER:
	set(value):
		if not state == value:
			state = value
			timer.start(1.0)
var move_direction := Vector3.ZERO
var speed = 40.0
var angle_y = 0.0

func _ready():
	character.lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(character))
	character.lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(character))
	anim_tree.active = true
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
			speed = 20.0
			toggle_look_at_mod(false)
			if character.hor_distance(home_position) > 100.0:
				var direction_to_home = character.hor_direction(home_position)
				move_direction = direction_to_home
			if timer.is_stopped():
				var rand := randf_range(-1.0, 1.0)
				move_direction = Vector3.FORWARD.rotated(Vector3.UP, rand * PI)
				timer.start(maxf(5.0, 15.0 * absf(rand)))
			var hor_vel = Vector2(character.velocity.z, character.velocity.x)
			if hor_vel:
				angle_y = hor_vel.angle() + PI
		CHASE:
			speed = 40.0
			toggle_look_at_mod(true)
			var distance = character.hor_distance(character.targeting.global_position)
			var direction = character.hor_direction(character.targeting.global_position)
			if distance < 35.0:
				move_direction = -direction
			elif distance < 65.0:
				move_direction = direction.rotated(Vector3.UP, PI/2.0)
			else:
				move_direction = direction
			if timer.is_stopped():
				character.weapons[0].activate(character.targeting)
				character.weapons[1].activate(character.targeting)
				timer.start(maxf(0.3, 1.0 * randf()))
			angle_y = Vector2(direction.z, direction.x).angle() + PI
		DEATH:
			toggle_look_at_mod(false)
			character.lock_on_marker.hide()
			move_direction = Vector3.ZERO
	var mult = 5.0
	if move_direction.x or move_direction.z:
		character.accelerate(move_direction, speed, mult)
	character.velocity += character.get_gravity() * delta * 6.0
	character.do_friction(mult)
	
	var rot_weight = 1 - pow(0.5, delta * 16.0)
	character.global_rotation.y = lerp_angle(character.rotation.y, angle_y, rot_weight)
	var weight := 1 - pow(0.5, delta * 4.0)
	var blend_pos: Vector2 = anim_tree.get('parameters/run/blend_position')
	var blend_dir = Vector2(move_direction.x, move_direction.z).rotated(character.rotation.y)
	blend_pos = blend_pos.lerp(blend_dir, weight)
	anim_tree.set('parameters/run/blend_position', blend_pos)
	anim_tree.set('parameters/slide/blend_position', blend_pos)
	anim_tree.set('parameters/airborne/blend_position', blend_pos)

func toggle_look_at_mod(enabled: bool):
	%LookAtLegBase.active = false
	%LookAtTorso.active = enabled
	%LookAtArmJointR.active = enabled
	%LookAtArmJointL.active = enabled
	%LookAtArmR.active = enabled
	%LookAtArmL.active = enabled
