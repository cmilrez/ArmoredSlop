extends Node

enum {WANDER, CHASE, DEATH}

@onready var atk_timer = $AtkTimer
@onready var move_timer = $MoveTimer

@export var character: Character = null
@export var anim_tree: AnimationTree = null
var home_position := Vector3.ZERO
var move_direction := Vector3.ZERO
var speed := 40.0
var angle_y := 0.0
var state := WANDER:
	set(value):
		if not state == value:
			state = value
			atk_timer.start(1.0)

func _ready():
	character.lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(character))
	character.lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(character))
	set_deferred(&'home_position', character.global_position)
	anim_tree.active = true
	character.set_weapons(character.weapons.duplicate()) # xd

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
			if move_timer.is_stopped():
				move_direction = Vector3.FORWARD.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI)
				move_timer.start(maxf(5.0, 15.0 * randf()))
			var hor_vel = Vector2(character.velocity.z, character.velocity.x)
			if hor_vel:
				angle_y = hor_vel.angle() + PI
		CHASE:
			speed = 40.0
			toggle_look_at_mod(true)
			var distance = character.hor_distance(character.targeting.global_position)
			var direction = character.hor_direction(character.targeting.global_position)
			if distance < 30.0:
				move_direction = -direction
			elif distance < 120.0:
				if move_timer.is_stopped():
					move_direction = character.global_basis.x.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI)
					move_timer.start(maxf(3.0, 5.0 * randf()))
			else:
				move_direction = direction
				move_timer.stop()
			angle_y = Vector2(direction.z, direction.x).angle() + PI
			if atk_timer.is_stopped():
				character.weapons[0].activate(character.targeting)
				character.weapons[1].activate(character.targeting)
				atk_timer.start(maxf(0.3, 1.0 * randf()))
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
	var weight := 1 - pow(0.5, delta * 24.0)
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
