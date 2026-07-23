class_name Robot extends Character

@onready var targeting = %Targeting

var active_melee_weapon: MeleeWeapon = null
var boosting := false

#func _ready():
	#pass

func set_weapons(nodes: Array[Weapon]):
	weapons.clear()
	var path = get_path()
	for weapon in nodes:
		weapons.append(weapon)
		weapon.set_dmg_source(path)

func _clear_melee_unit():
	if active_melee_weapon:
		active_melee_weapon.cooldown()
	active_melee_weapon = null

func _on_animation_tree_toggled_melee_hurtbox(enabled):
	if active_melee_weapon:
		active_melee_weapon.toggle_hurtbox(enabled)
