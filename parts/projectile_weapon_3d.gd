@icon('res://addons/at-icons/node3d/gun.svg')
class_name ProjectileWeapon3D extends Weapon3D

const START_ANIM = &'Start'
const READY_ANIM = &'Ready'
const SHOOT_ANIM = &'Shoot'
const RELOAD_ANIM = &'Reload'

signal shot_fired
signal ammo_changed(loaded: int, left: int)

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

@export var spawners: Node3D = null
@export var infinite_ammo := false
@export var param: ProjectileWeaponParam = null
var damage_data: DamageData = null
var ammo_total := 0
var ammo_loaded := 0:
	set(value):
		value = clampi(value, 0, param.clip_size)
		ammo_loaded = value
		ammo_changed.emit(ammo_loaded, ammo_left)
		check_ammo()
var ammo_left := 0:
	set(value):
		value = clampi(value, 0, param.ammo_max)
		ammo_left = value
		ammo_changed.emit(ammo_loaded, ammo_left)
		check_ammo()
var ammo_empty := false

func check_ammo() -> void:
	ammo_total = ammo_loaded + ammo_left
	if ammo_total <= 0 and not ammo_empty:
		ammo_empty = true
		_state_shutdown()
	if ammo_total > 0 and ammo_empty:
		ammo_empty = false
		_state_start()
		reload(true)

func _ready():
	timer.one_shot = true
	timer.timeout.connect(func (): if reloading: reload())
	damage_data = DamageData.new()
	damage_data.kinetic_damage = param.kinetic_damage
	damage_data.energy_damage = param.energy_damage
	damage_data.explosive_damage = param.explosive_damage
	ammo_loaded = param.clip_size
	ammo_left = param.ammo_max
	ammo_changed.emit.call_deferred(ammo_loaded, ammo_left)
	_state_start()

func activate(targets: Array[Character] = [], aim_position := Vector3.ZERO) -> void:
	if not can_use:
		return
	_state_shoot()
	var spawn_count = spawners.get_child_count()
	var target_count = targets.size()
	var i = spawn_count
	for spawn: Node3D in spawners.get_children():
		if ammo_loaded <= 0:
			break
		var new_projectile = param.projectile_scene.instantiate()
		get_tree().current_scene.add_child(new_projectile)
		var target = targets[(spawn_count - i) % target_count] if target_count else null
		var target_position = target.get_lock_position() if target else aim_position
		new_projectile.set_up(spawn, damage_data, target_position, target)
		ammo_loaded -= param.ammo_cost
		i -= 1
		if param.multishot_interval > 0.0 and spawn_count > 0:
			timer.start(param.multishot_interval)
			await timer.timeout
	if ammo_loaded <= 0:
		if ammo_left > 0 and not reloading:
			_state_reload()
		return
	if param.shot_interval > 0.0:
		timer.start(param.shot_interval)
		await timer.timeout
	can_use = true

func set_dmg_source(path: NodePath) -> void:
	if damage_data:
		damage_data.source = path

func reload(manual_reload := false) -> void:
	if ammo_left <= 0:
		reloading = false
		return
	var difference = param.clip_size - ammo_loaded
	if difference <= 0: # clip full
		return
	if manual_reload:
		if not reloading:
			_state_reload()
		return
	if infinite_ammo:
		ammo_loaded = param.clip_size
	else:
		if difference < ammo_left:
			ammo_loaded = param.clip_size
			ammo_left -= difference
		else:
			ammo_loaded += ammo_left
			ammo_left = 0
	reloading = false
	_state_ready()

func _state_start() -> void:
	can_use = false
	if anim_player.has_animation(START_ANIM):
		anim_player.play(START_ANIM)
		await anim_player.animation_finished
	can_use = true

func _state_ready() -> void:
	if anim_player.has_animation(READY_ANIM):
		anim_player.play(READY_ANIM)
		if anim_player.get_animation(READY_ANIM).get_loop_mode() == Animation.LOOP_NONE:
			await anim_player.animation_finished
	can_use = true

func _state_shoot() -> void:
	can_use = false
	shot_fired.emit()
	if anim_player.has_animation(SHOOT_ANIM):
		anim_player.play(SHOOT_ANIM)

func _state_reload() -> void:
	can_use = false
	reloading = true
	timer.start(param.reload_time)
	if anim_player.has_animation(RELOAD_ANIM):
		anim_player.queue(RELOAD_ANIM)

func _state_shutdown() -> void:
	can_use = false
	if anim_player.has_animation(START_ANIM):
		if anim_player.is_playing():
			await anim_player.animation_finished
		anim_player.play_backwards(START_ANIM)
