class_name NPC extends Character

@onready var anim_tree = $Droid/AnimationTree
@onready var health = $Health
@onready var targeting = %Targeting
@onready var look_at_mod = %LookAtMod
@onready var npc_weapon = $NPCWeapon

var home_position := Vector3.ZERO

func _ready():
	lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(self))
	lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(self))
	home_position = global_position
	anim_tree.active = true
	npc_weapon.damage_data = npc_weapon.damage_data.duplicate()
	npc_weapon.damage_data.source = get_path()

func _physics_process(delta):
	var root_motion = quaternion * anim_tree.get_root_motion_position() / delta
	velocity.x = root_motion.x
	velocity.z = root_motion.z
	if not is_on_floor():
		gravity = get_gravity()
		velocity += gravity * delta * 6.0
	if not targeting.target:
		targeting.position = Vector3(0.0, 4.0, 10.0)
	if alive:
		update_animation(delta)
		for i in get_slide_collision_count():
			if not velocity: continue
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	move_and_slide()

func update_animation(delta: float):
	var angle = global_basis.z.signed_angle_to(move_direction, Vector3.UP)
	anim_tree.set('parameters/Default/Move/blend_position', Vector2.UP)
	if targeting.target:
		look_at_mod.active = true
		anim_tree.set('parameters/Default/Speed/scale', 3.0)
	else:
		look_at_mod.active = false
		anim_tree.set('parameters/Default/Speed/scale', 1.0)
		if angle > Global.QUARTER_PI:
			anim_tree.set('parameters/Default/Move/blend_position', Vector2.LEFT)
		elif angle < -Global.QUARTER_PI:
			anim_tree.set('parameters/Default/Move/blend_position', Vector2.RIGHT)
	quaternion = quaternion * anim_tree.get_root_motion_rotation()
	rotate_y(sign(angle) * minf(absf(angle), delta))
