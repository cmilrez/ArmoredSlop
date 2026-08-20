extends Control

const rect_offset = Vector2(24.0, 24.0)
const lock_region_y_offset := -50.0

@onready var player: Robot = get_parent()
@onready var camera: PlayerCamera = %PlayerCamera
@onready var tracker: Tracker = %Tracker
@onready var ammo_labels: HBoxContainer = $AmmoLabels
@onready var lock_on_bars: Control = $AimRect1/LockOnBars
@onready var armor_label: Label = $Armor
@onready var aim_rects: Array[TextureRect] = [$AimRect1, $AimRect2, $AimRect3, $AimRect4, $AimRect5, $AimRect6, $AimRect7, $AimRect8]

func _ready():
	player.data.lock_on.changed.connect(queue_redraw)

func _process(delta):
	_update_velocimeter()
	_update_aim_rects()
	_update_lock_progression()

func _draw():
	var lock_data = player.data.lock_on
	if not lock_data:
		return
	var center = get_viewport().get_visible_rect().size / 2.0
	var half_size = lock_data.region.size / 2.0
	lock_data.region.position = center - half_size
	lock_data.region.position.y += lock_region_y_offset
	draw_rect(lock_data.region, Color.GREEN, false, 4.0)

func _update_velocimeter() -> void:
	var vel = Vector2(player.velocity.x, player.velocity.z).length()
	$Velocity.text = '%.0f Km/h' % [vel * 3.6]

func _update_aim_rects() -> void:
	aim_rects[0].position = camera.get_unprojected(tracker.position) - rect_offset
	var list_size = camera.multi_target_list.size()
	for i in range(1, aim_rects.size()):
		if i > list_size:
			aim_rects[i].visible = false
			continue
		var target_pos = camera.multi_target_list[i - 1].get_lock_position()
		aim_rects[i].visible = true
		aim_rects[i].position = camera.get_unprojected(target_pos) - rect_offset

func _update_lock_progression() -> void:
	for i in range(lock_on_bars.get_child_count()):
		var unit = player.weapons[i]
		if unit:
			if unit is ProjectileWeapon3D:
				var bar: TextureProgressBar = lock_on_bars.get_child(i)
				if tracker.is_target_valid():
					var total_duration = unit.param.single_lock_duration - player.data.lock_on.single_duration
					var value: float
					if total_duration > 0.0:
						value = player.single_lock_time / total_duration
					else:
						value = 1.0
					bar.value = value * 100.0
				else:
					bar.value = 0.0

func _update_armor_display(value: float) -> void:
	value = ceilf(value)
	armor_label.text = '%.0f' % value

func _update_ammo_display(loaded: int, left: int, id: int) -> void:
	var child: Label = ammo_labels.get_child(id)
	if loaded or left:
		child.text = str(loaded) + ' / ' + str(left)
		return
	child.text = '-EMPTY-'

func _on_weapon_started_reloading(id: int) -> void:
	var child: Label = ammo_labels.get_child(id)
	child.text = '-RELOADING-'

func _on_builder_weapons_built(nodes: Array[Weapon3D]):
	var i = 0
	for node in nodes:
		if node:
			if node is ProjectileWeapon3D:
				node.ammo_changed.connect(_update_ammo_display.bind(i))
				node.started_reloading.connect(_on_weapon_started_reloading.bind(i))
				_update_ammo_display(node.ammo_loaded, node.ammo_left, i)
				lock_on_bars.get_child(i).show()
			elif node is MeleeWeapon:
				ammo_labels.get_child(i).text = 'MELEE'
				lock_on_bars.get_child(i).hide()
		else:
			ammo_labels.get_child(i).text = 'NONE'
			lock_on_bars.get_child(i).hide()
		i += 1
