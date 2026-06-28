class_name PlayerRobot extends Character

@onready var targeting = %Targeting

var active_melee_unit: MeleeWeapon = null

func _ready():
	%LookAtTorso.active = true
	%LookAtArmJointR.active = true
	%LookAtArmJointL.active = true
	%LookAtArmR.active = true
	%LookAtArmL.active = true

func _physics_process(delta):
	%LookAtLegBase.active = not is_on_floor()
	if alive:
		for i in get_slide_collision_count():
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	move_and_slide()

func set_weapons(nodes: Array[Node]):
	weapons.clear()
	for node in nodes:
		weapons.append(node)

func _clear_melee_unit():
	if active_melee_unit:
		active_melee_unit.cooldown()
	active_melee_unit = null

func _on_melee_attack_started():
	if active_melee_unit:
		active_melee_unit.attack()

func _on_animation_tree_toggled_melee_hurtbox(enabled):
	if active_melee_unit:
		active_melee_unit.toggle_hurtbox(enabled)
