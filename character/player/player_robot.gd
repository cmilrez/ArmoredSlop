class_name PlayerRobot extends Character

@onready var targeting = %Targeting

var active_melee_weapon: MeleeWeapon = null

func _ready():
	%LookAtTorso.active = true
	%LookAtArmJointR.active = true
	%LookAtArmJointL.active = true
	%LookAtArmR.active = true
	%LookAtArmL.active = true

func _physics_process(delta):
	if alive:
		for i in get_slide_collision_count():
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	move_and_slide()

func set_weapons(nodes: Array[Node]):
	weapons.clear()
	var path = get_path()
	for node: ProjectileWeapon in nodes:
		weapons.append(node)
		node.set_dmg_source(path)

func _clear_melee_unit():
	if active_melee_weapon:
		active_melee_weapon.cooldown()
	active_melee_weapon = null

func _on_animation_tree_toggled_melee_hurtbox(enabled):
	if active_melee_weapon:
		active_melee_weapon.toggle_hurtbox(enabled)
