extends Control

@onready var armor_label = $Armor
@onready var h_box_container = $HBoxContainer

func _process(delta):
	var vel = Vector2(owner.velocity.x, owner.velocity.z).length()
	$Velocity.text = '%.0f Km/h' % [vel * 3.6]

func _update_armor_display(value: float) -> void:
	armor_label.text = '%.0f' % value

func _update_ammo_display(loaded: int, left: int, id: int) -> void:
	var child: Label = h_box_container.get_child(id)
	if loaded or left:
		child.text = str(loaded) + ' / ' + str(left)
		return
	child.text = '-EMPTY-'

func _on_weapon_started_reloading(id: int) -> void:
	var child: Label = h_box_container.get_child(id)
	child.text = '-RELOADING-'

func _on_builder_weapons_built(nodes: Array[Weapon]):
	var i = 0
	for node in nodes:
		if node:
			if node is ProjectileWeapon:
				node.ammo_changed.connect(_update_ammo_display.bind(i))
				node.started_reloading.connect(_on_weapon_started_reloading.bind(i))
				_update_ammo_display(node.ammo_loaded, node.ammo_left, i)
			elif node is MeleeWeapon:
				h_box_container.get_child(i).text = 'MELEE'
		else:
			h_box_container.get_child(i).text = 'NONE'
		i += 1
