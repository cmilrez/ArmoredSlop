class_name Weapon3D extends Node3D

signal reload_started
signal shot_fired
signal ammo_changed(loaded: int, left: int)

const START_ANIM = &'Start'
const READY_ANIM = &'Ready'
const ACTIVE_ANIM = &'Active'
const CHARGING_ANIM = &'Charging'
const RELOAD_ANIM = &'Reload'
const SHUTDOWN_ANIM = &'Shutdown'
enum {START, READY, ACTIVE, CHARGING, RELOAD, SHUTDOWN}

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
var state: int = START:
	set(value):
		if not state == value:
			state = value
			_state_start()
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

func _ready():
	timer.one_shot = true
	timer.timeout.connect(_reload)
	damage_data = param.get_damage_data()
	ammo_loaded = param.clip_size
	ammo_left = param.ammo_max
	ammo_changed.emit.call_deferred(ammo_loaded, ammo_left)
	_state_start()

func activate(ctx: TargetContext) -> void:
	if state == READY:
		target_ctx = ctx
		state = ACTIVE

func is_online() -> bool:
	return state == READY or state == ACTIVE or state == CHARGING

func check_ammo() -> void:
	if state == SHUTDOWN:
		if ammo_loaded + ammo_left > 0:
			state = START
			_reload()

func shoot_one(spawner_idx := 0) -> void:
	if ammo_loaded <= 0:
		interrupt()
		return
	var list_size = target_ctx.list.size()
	var spawn = spawners.get_child(spawner_idx)
	var new_projectile = param.projectile_scene.instantiate()
	get_tree().current_scene.add_child(new_projectile)
	var target = target_ctx.list[spawner_idx % list_size] if list_size else null
	var target_position = target.get_lock_position() if target else target_ctx.tracker.position
	new_projectile.set_up(spawn, damage_data, target_position, target)
	ammo_loaded -= param.ammo_cost
	shot_fired.emit()

func shoot_many() -> void:
	var it_shot_once = false
	for spawn in spawners.get_children():
		if ammo_loaded <= 0:
			interrupt()
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

func interrupt() -> void:
	if state == READY:
		return
	if ammo_loaded > 0:
		state = READY
	elif ammo_left > 0:
		state = RELOAD
	else:
		state = SHUTDOWN

func set_dmg_source(path: NodePath) -> void:
	if damage_data:
		damage_data.source = path

func manual_reload() -> void:
	if not state == READY:
		return
	if ammo_left <= 0:
		return
	if param.clip_size <= ammo_loaded:
		return # clip full
	state = RELOAD

func _reload() -> void:
	if infinite_ammo:
		ammo_loaded = param.clip_size
	else:
		var difference = param.clip_size - ammo_loaded
		if difference < ammo_left:
			ammo_loaded = param.clip_size
			ammo_left -= difference
		else:
			ammo_loaded += ammo_left
			ammo_left = 0
	state = READY

func _state_start() -> void:
	match state:
		START:
			if anim_player.has_animation(START_ANIM):
				anim_player.play(START_ANIM)
				await anim_player.current_animation_changed
			state = READY
		READY:
			if anim_player.has_animation(READY_ANIM):
				anim_player.play(READY_ANIM)
		ACTIVE:
			anim_player.play(ACTIVE_ANIM)
			await anim_player.current_animation_changed
			interrupt()
		CHARGING:
			if anim_player.has_animation(CHARGING_ANIM):
				anim_player.play(CHARGING_ANIM)
		RELOAD:
			if param.reload_time:
				timer.start(param.reload_time)
				reload_started.emit()
			else:
				timer.timeout.emit()
			if anim_player.has_animation(RELOAD_ANIM):
				anim_player.play(RELOAD_ANIM)
		SHUTDOWN:
			if anim_player.has_animation(SHUTDOWN_ANIM):
				anim_player.play(SHUTDOWN_ANIM)
