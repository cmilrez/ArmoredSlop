class_name RobotHUD extends Control

const REGION_Y_OFFSET := -50.0

@onready var player: Robot3D = get_parent()
@onready var camera: PlayerCamera3D = %PlayerCamera3D
@onready var tracker: Tracker3D = %Tracker3D
@onready var ammo_labels: HBoxContainer = $AmmoLabels
@onready var lock_on_bars: Control = $AimRect1/LockOnBars
@onready var armor_label: Label = $Armor
@onready var aim_rects: Array[TextureRect] = [$AimRect1, $AimRect2, $AimRect3, $AimRect4, $AimRect5, $AimRect6, $AimRect7, $AimRect8]

var aim_rect_offset := Vector2(24.0, 24.0)
var lock_on_rect := Rect2()

func _ready():
	aim_rect_offset = aim_rects[0].size / 2.0
	player.data.lock_on.changed.connect(queue_redraw)

func _process(delta):
	_update_velocimeter()
	_update_aim_rects()
	_update_lock_progression()

func _draw():
	if not player.data.lock_on:
		return
	var region_size = player.data.lock_on.region_size
	var view_center = get_viewport().get_visible_rect().size / 2.0
	var pos: Vector2 = view_center - (region_size * 0.5)
	pos.y += REGION_Y_OFFSET
	lock_on_rect = Rect2(pos, region_size)
	draw_rect(lock_on_rect, Color(Color.GREEN, 0.7), false, 4.0)

func _update_velocimeter() -> void:
	var vel = Vector2(player.velocity.x, player.velocity.z).length()
	$Velocity.text = '%.0f Km/h' % [vel * 3.6]

func _update_aim_rects() -> void:
	aim_rects[0].position = camera.get_unprojected(tracker.position) - aim_rect_offset
	var list_size = camera.multi_target_list.size()
	for i in range(1, aim_rects.size()):
		aim_rects[i].visible = i <= list_size
		if aim_rects[i].visible:
			var pos_3d = camera.multi_target_list[i - 1].get_lock_position()
			aim_rects[i].position = camera.get_unprojected(pos_3d) - aim_rect_offset

func _update_lock_progression() -> void:
	for i in range(lock_on_bars.get_child_count()):
		var wp = player.weapons[i]
		if not wp:
			continue
		var bar = lock_on_bars.get_child(i)
		if wp.reloading:
			bar.value = 0.0
			continue
		if wp is ProjectileWeapon3D:
			if tracker.is_target_valid():
				var value: float
				var duration = player.get_unit_lock_duration(i)
				if duration > 0.0:
					value = player.unit_lock_time[i] / duration
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
			elif node is MeleeWeapon3D:
				ammo_labels.get_child(i).text = 'MELEE'
				lock_on_bars.get_child(i).hide()
		else:
			ammo_labels.get_child(i).text = 'NONE'
			lock_on_bars.get_child(i).hide()
		i += 1
