extends Control

@onready var armor_label = $Armor
@onready var h_box_container = $HBoxContainer

func _process(delta):
	var vel = Vector2(owner.velocity.x, owner.velocity.z).length()
	$Velocity.text = '%.0f Km/h' % [vel * 3.6]

func update_armor_display(value: float):
	armor_label.text = '%.0f' % value

func update_ammo_display(loaded: int, left: int, id: int):
	var child: Label = h_box_container.get_child(id)
	if not loaded and left:
		child.text = '-RELOADING-'
		return
	if loaded or left:
		child.text = str(loaded) + ' / ' + str(left)
		return
	child.text = '-EMPTY-'

func _on_builder_weapons_built(nodes):
	var i = 0
	for node in nodes:
		if node is ProjectileWeapon:
			node.ammo_changed.connect(update_ammo_display.bind(i))
		i += 1
