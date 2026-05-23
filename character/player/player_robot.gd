class_name Player extends Character

@onready var camera = $PlayerCamera
@onready var anim_tree = $AnimationTree
@onready var state_machine = $StateMachine
@onready var health = $Health
@onready var targeting = %Targeting
@onready var robot_hud = $RobotHud

var right_arm_unit: Weapon = null
var left_arm_unit: Weapon = null
var right_back_unit: Weapon = null
var left_back_unit: Weapon = null
var active_melee_unit: MeleeWeapon = null
var input_direction := Vector2.ZERO

func _ready():
	anim_tree.active = true
	setup_parts()

func _physics_process(delta):
	gravity = get_gravity()
	if alive:
		input_direction.x = Input.get_axis('move_left', 'move_right')
		input_direction.y = Input.get_axis('move_forward', 'move_backward')
		move_direction = Vector3(input_direction.x, Input.get_action_strength('move_up'), input_direction.y)
		move_direction = move_direction.rotated(Vector3.UP, camera.spring_arm.rotation.y).normalized()
		for i in get_slide_collision_count():
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	update_anim_param(delta)
	move_and_slide()

func update_anim_param(delta: float):
	var weight := 1 - pow(0.5, delta * 4)
	var blend_position: Vector2 = anim_tree.get('parameters/slide/blend_position')
	blend_position = blend_position.lerp(input_direction, weight)
	anim_tree.set('parameters/airborne/blend_position', blend_position)
	anim_tree.set('parameters/slide/blend_position', blend_position)

func face_camera(delta: float):
	var rot_weight = 1 - pow(0.5, delta * 8)
	global_rotation.y = lerp_angle(rotation.y, camera.spring_arm.rotation.y, rot_weight)

func accelerate(wish_dir: Vector3, speed: float, delta: float) -> Vector3:
	var h_vel = Vector3(velocity.x, 0.0, velocity.z)
	var vel_dir = (wish_dir * speed) - h_vel
	var wish_speed = vel_dir.length()
	var acceleration = minf(wish_speed, speed * delta * 2.0)
	if is_zero_approx(wish_speed):
		return Vector3.ZERO
	return acceleration * vel_dir / wish_speed

	#var add_speed = speed - velocity.dot(wish_dir)
	#if add_speed <= 0.0:
		#return Vector3.ZERO
	#var acceleration = minf(10.0 * delta * speed, add_speed)
	#return acceleration * wish_dir

func activate_units():
	if left_arm_unit:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_left'):
				left_arm_unit.reload(true)
		if Input.is_action_pressed('arm_unit_left'):
			if left_arm_unit is MeleeWeapon:
				if left_arm_unit.can_use:
					active_melee_unit = left_arm_unit
			left_arm_unit.activate(targeting)
	if right_arm_unit:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_right'):
				right_arm_unit.reload(true)
		if Input.is_action_pressed('arm_unit_right'):
			if right_arm_unit is MeleeWeapon:
				if right_arm_unit.can_use:
					active_melee_unit = right_arm_unit
			right_arm_unit.activate(targeting)
	if right_back_unit:
		if Input.is_action_pressed('back_unit_right'):
			right_back_unit.activate(targeting)
	if left_back_unit:
		if Input.is_action_pressed('back_unit_left'):
			left_back_unit.activate(targeting)

func setup_parts():
	var legs: BodyPart = data.legs_part.instantiate()
	var torso: BodyPart = data.torso_part.instantiate()
	var arms: BodyPart = data.arms_part.instantiate()
	var head: BodyPart = data.head_part.instantiate()
	data.max_hp = legs.data.defense_bullet + torso.data.armor + arms.data.armor + head.data.armor
	data.defense_bullet = (legs.data.defense_bullet + torso.data.defense_bullet + arms.data.defense_bullet + head.data.defense_bullet) / 1000.0
	data.defense_energy = (legs.data.defense_energy + torso.data.defense_energy + arms.data.defense_energy + head.data.defense_energy) / 1000.0
	data.defense_explosive = (legs.data.defense_explosive + torso.data.defense_explosive + arms.data.defense_explosive + head.data.defense_explosive) / 1000.0
	%Skeleton3D.add_child(legs)
	%Skeleton3D.add_child(torso)
	%Skeleton3D.add_child(arms)
	%Skeleton3D.add_child(head)
	legs.skeleton = %Skeleton3D.get_path()
	torso.skeleton = %Skeleton3D.get_path()
	arms.skeleton = %Skeleton3D.get_path()
	head.skeleton = %Skeleton3D.get_path()
	#var skin = %Skeleton3D.create_skin_from_rest_transforms()
	#legs.skin = skin
	#torso.skin = skin
	#arms.skin = skin
	#head.skin = skin
	
	var node_path = get_path()
	
	right_arm_unit = data.right_arm_part.instantiate()
	%ArmUnitR.add_child(right_arm_unit)
	right_arm_unit.data.damage_data.source = node_path
	right_arm_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(0))
	
	left_arm_unit = data.left_arm_part.instantiate()
	%ArmUnitL.add_child(left_arm_unit)
	left_arm_unit.data.damage_data.source = node_path
	left_arm_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(1))
	
	right_back_unit = data.right_back_part.instantiate()
	%BackUnitR.add_child(right_back_unit)
	right_back_unit.data.damage_data.source = node_path
	right_back_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(2))
	
	left_back_unit = data.left_back_part.instantiate()
	%BackUnitL.add_child(left_back_unit)
	left_back_unit.data.damage_data.source = node_path
	left_back_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(3))

func clear_melee_unit():
	if active_melee_unit:
		active_melee_unit.cooldown()
	active_melee_unit = null

func _on_melee_attack_started():
	if active_melee_unit:
		active_melee_unit.attack()

func _on_animation_tree_toggled_melee_hurtbox(enabled):
	if active_melee_unit:
		active_melee_unit.toggle_hurtbox(enabled)
