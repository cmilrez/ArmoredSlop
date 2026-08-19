extends Control

const rect_offset = Vector2(24.0, 24.0)

@onready var h_box_container: HBoxContainer = $HBoxContainer
@onready var armor_label: Label = $Armor
@onready var camera: PlayerCamera = %PlayerCamera
@onready var tracker: Tracker = %Tracker
@onready var aim_rects: Array[TextureRect] = [$AimRect1, $AimRect2, $AimRect3, $AimRect4, $AimRect5, $AimRect6, $AimRect7, $AimRect8]

func _process(delta):
	var vel = Vector2(owner.velocity.x, owner.velocity.z).length()
	$Velocity.text = '%.0f Km/h' % [vel * 3.6]
	aim_rects[0].position = camera.get_unprojected(tracker.position) - rect_offset
	var list_size = camera.multi_target_list.size()
	for i in range(1, aim_rects.size()):
		if i > list_size:
			aim_rects[i].visible = false
			continue
		var target_pos = camera.multi_target_list[i - 1].get_lock_position()
		aim_rects[i].visible = true
		aim_rects[i].position = camera.get_unprojected(target_pos) - rect_offset

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

func _on_builder_weapons_built(nodes: Array[Weapon3D]):
	var i = 0
	for node in nodes:
		if node:
			if node is ProjectileWeapon3D:
				node.ammo_changed.connect(_update_ammo_display.bind(i))
				node.started_reloading.connect(_on_weapon_started_reloading.bind(i))
				_update_ammo_display(node.ammo_loaded, node.ammo_left, i)
			elif node is MeleeWeapon:
				h_box_container.get_child(i).text = 'MELEE'
		else:
			h_box_container.get_child(i).text = 'NONE'
		i += 1
