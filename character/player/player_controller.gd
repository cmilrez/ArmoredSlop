extends Node

@export var character: Character = null
@export var camera: PlayerCamera = null
@export var anim_tree: AnimationTree = null
var input_direction := Vector2.ZERO
var move_direction := Vector3.ZERO
var speed = 50.0

func _ready():
	pass

func _process(delta):
	input_direction.x = Input.get_axis('move_left', 'move_right')
	input_direction.y = Input.get_axis('move_forward', 'move_backward')
	move_direction = Vector3(input_direction.x, 0.0, input_direction.y)
	move_direction = move_direction.rotated(Vector3.UP, camera.spring_arm.rotation.y).normalized()
	activate_units()

func _physics_process(delta):
	var mult = 5.0
	if Input.is_action_pressed('move_up'):
		if character.is_on_floor():
			if not move_direction:
				character.velocity.y = 30.0
			elif not character.boosting:
				character.boosting = true
				speed = 120.0
			elif Input.is_action_just_pressed('move_up'):
				character.accelerate_up(30.0, mult)
		else:
			character.accelerate_up(30.0, mult)
	if character.is_on_floor():
		if character.boosting:
			speed = move_toward(speed, 60.0, 60.0 * delta)
		else:
			speed = move_toward(speed, 40.0, 40.0 * delta)
	else:
		speed = move_toward(speed, 50.0, 35.0 * delta)
	if move_direction.x or move_direction.z:
		character.accelerate(move_direction, speed, mult)
	character.velocity += character.get_gravity() * delta * 6.0
	character.do_friction(mult)
	
	var weight := 1 - pow(0.5, delta * 24.0)
	var blend_position: Vector2 = anim_tree.get('parameters/run/blend_position')
	blend_position = blend_position.lerp(input_direction, weight)
	anim_tree.set('parameters/run/blend_position', blend_position)
	anim_tree.set('parameters/slide/blend_position', blend_position)
	anim_tree.set('parameters/airborne/blend_position', blend_position)
	var rot_weight = 1 - pow(0.5, delta * 16.0)
	character.global_rotation.y = lerp_angle(character.rotation.y, camera.spring_arm.rotation.y, rot_weight)

func _unhandled_input(event):
	if event.is_action_released('move_up'):
		if character.boosting:
			await get_tree().create_timer(0.4).timeout
			if not Input.is_action_pressed('move_up'):
				character.boosting = false

func activate_units():
	var weapons = character.weapons
	var size = weapons.size()
	if size > 0:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_right'):
				weapons[0].reload(true)
		if Input.is_action_pressed('arm_unit_right'):
			if weapons[0] is MeleeWeapon:
				if weapons[0].can_use:
					character.active_melee_unit = weapons[0]
			weapons[0].activate(character.targeting)
	if size > 1:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_left'):
				weapons[1].reload(true)
		if Input.is_action_pressed('arm_unit_left'):
			if weapons[1] is MeleeWeapon:
				if weapons[1].can_use:
					character.active_melee_unit = weapons[1]
			weapons[1].activate(character.targeting)
	if size > 2:
		if Input.is_action_pressed('back_unit_right'):
			weapons[2].activate(character.targeting)
	if size > 3:
		if Input.is_action_pressed('back_unit_left'):
			weapons[3].activate(character.targeting)
