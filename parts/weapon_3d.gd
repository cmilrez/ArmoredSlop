class_name Weapon3D extends Node3D

signal started_reloading
signal shot_fired
signal ammo_changed(loaded: int, left: int)

const START_ANIM = &'Start'
const READY_ANIM = &'Ready'
const MELEE_ANIM = &'Melee'
const SHOOT_ANIM = &'Shoot'
const RELOAD_ANIM = &'Reload'

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

@export var left_side := false:
	set(value):
		left_side = value
		scale.x = -1.0 if left_side else 1.0
@export var spawners: Node3D = null
@export var infinite_ammo := false
@export var param: WeaponParam = null
var target_ctx: TargetContext = null
var damage_data: DamageData = null
var reloading := false:
	set(value):
		var emit = not reloading and value
		reloading = value
		if emit:
			started_reloading.emit()
var can_use := false
var ammo_empty := false
var ammo_loaded := 0:
	set(value):
		value = clampi(value, 0, param.clip_size)
		ammo_loaded = value
		ammo_changed.emit(ammo_loaded, ammo_left)
		check_ammo_total()
var ammo_left := 0:
	set(value):
		value = clampi(value, 0, param.ammo_max)
		ammo_left = value
		ammo_changed.emit(ammo_loaded, ammo_left)
		check_ammo_total()

func _ready():
	timer.one_shot = true
	timer.timeout.connect(reload)
	damage_data = DamageData.new()
	damage_data.kinetic_damage = param.kinetic_damage
	damage_data.energy_damage = param.energy_damage
	damage_data.explosive_damage = param.explosive_damage
	ammo_loaded = param.clip_size
	ammo_left = param.ammo_max
	ammo_changed.emit.call_deferred(ammo_loaded, ammo_left)
	_state_start()

func check_ammo_total() -> void:
	var ammo_total = ammo_loaded + ammo_left
	if ammo_total <= 0 and not ammo_empty:
		ammo_empty = true
		_state_shutdown()
		return
	if ammo_total > 0 and ammo_empty:
		ammo_empty = false
		await _state_start()
		reload(true)

func check_ammo_loaded() -> bool:
	var value = ammo_loaded <= 0
	if value:
		if ammo_left > 0:
			_state_reload()
	return value

func activate(ctx: TargetContext) -> void:
	if can_use:
		target_ctx = ctx
		_state_shoot()

func shoot_one(spawner_idx := 0) -> void:
	check_ammo_loaded()
	var list_size = target_ctx.list.size()
	var spawn = spawners.get_child(spawner_idx)
	var new_projectile = param.projectile_scene.instantiate()
	get_tree().current_scene.add_child(new_projectile)
	var target = target_ctx.list[spawner_idx % list_size] if list_size else null
	var target_position = target.get_lock_position() if target else target_ctx.tracker.position
	new_projectile.set_up(spawn, damage_data, target_position, target)
	ammo_loaded -= param.ammo_cost
	shot_fired.emit()
	check_ammo_loaded()

func shoot_many() -> void:
	var it_shot_once = false
	for spawn in spawners.get_children():
		if check_ammo_loaded():
			interrupt_anim()
			break
		var new_projectile = param.projectile_scene.instantiate()
		get_tree().current_scene.add_child(new_projectile)
		var target = target_ctx.list[-1] if target_ctx.list else null
		var target_position = target.get_lock_position() if target else target_ctx.tracker.position
		new_projectile.set_up(spawn, damage_data, target_position, target)
		ammo_loaded -= param.ammo_cost
		it_shot_once = true
	if it_shot_once:
		shot_fired.emit()
	check_ammo_loaded()

func start_melee() -> void:
	if can_use:
		_state_melee()

func interrupt_anim() -> void:
	anim_player.stop()

func set_dmg_source(path: NodePath) -> void:
	if damage_data:
		damage_data.source = path

func reload(manual_reload := false) -> void:
	if ammo_left <= 0:
		reloading = false
		return
	var difference = param.clip_size - ammo_loaded
	if difference <= 0:
		return # clip full
	if manual_reload:
		if not reloading and can_use:
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
	anim_player.play(SHOOT_ANIM)
	await anim_player.animation_finished
	if ammo_loaded > 0:
		can_use = true

func _state_melee() -> void:
	can_use = false
	if anim_player.has_animation(MELEE_ANIM):
		anim_player.play(MELEE_ANIM)

func _state_reload() -> void:
	can_use = false
	reloading = true
	if param.reload_time:
		timer.start(param.reload_time)
	else:
		timer.timeout.emit()
	if anim_player.has_animation(RELOAD_ANIM):
		anim_player.queue(RELOAD_ANIM)

func _state_shutdown() -> void:
	can_use = false
	if anim_player.has_animation(START_ANIM):
		if anim_player.is_playing():
			await anim_player.animation_finished
		anim_player.play_backwards(START_ANIM)
