class_name ProjectileWeapon extends Weapon

const START_ANIM = &'Start'
const READY_ANIM = &'Ready'
const SHOOT_ANIM = &'Shoot'
const RELOAD_ANIM = &'Reload'

@export var spawners: Node3D = null
@export var data: ProjectileWeaponData = null
var ammo_total := 0
var ammo_loaded := 0:
	set(value):
		value = clampi(value, 0, data.clip_size)
		ammo_loaded = value
		check_ammo()
var ammo_left := 0:
	set(value):
		value = clampi(value, 0, data.ammo_max)
		ammo_left = value
		check_ammo()
var ammo_empty := false

func check_ammo():
	ammo_total = ammo_loaded + ammo_left
	if ammo_total <= 0 and not ammo_empty:
		ammo_empty = true
		_anim_shutdown()
	if ammo_total > 0 and ammo_empty:
		ammo_empty = false
		_anim_start()
		reload(true)

func _ready():
	super._ready()
	timer.timeout.connect(func (): if reloading: reload())
	ammo_loaded = data.clip_size
	ammo_left = data.ammo_max
	_anim_start()

func activate(targeting: Targeting):
	if not can_use:
		return
	_anim_shoot()
	var spawn_count := spawners.get_child_count()
	for spawn: Node3D in spawners.get_children():
		if ammo_loaded <= 0:
			break
		spawn_count -= 1
		var new_projectile = data.projectile_scene.instantiate()
		var target_position = targeting.get_targeting_position(new_projectile.data.speed, spawn.global_position)
		get_tree().current_scene.add_child(new_projectile)
		if new_projectile is Bullet:
			new_projectile.set_up(spawn.global_position, spawn.rotation, data.damage_data, target_position)
		elif new_projectile is Missile:
			new_projectile.set_up(spawn.global_transform, data.damage_data, target_position, targeting.target)
		ammo_loaded -= data.ammo_cost
		if data.multishot_interval > 0.0 and spawn_count > 0:
			timer.start(data.multishot_interval)
			await timer.timeout
	if ammo_loaded <= 0:
		if ammo_left > 0 and not reloading:
			_anim_reload()
		return
	if data.shot_interval > 0.0:
		timer.start(data.shot_interval)
		await timer.timeout
	can_use = true

func reload(manual_reload := false):
	if ammo_left <= 0:
		reloading = false
		return
	var difference = data.clip_size - ammo_loaded
	if difference <= 0:
		return # clip full
	if manual_reload:
		if not reloading:
			_anim_reload()
		return
	if difference < ammo_left:
		ammo_loaded = data.clip_size
		ammo_left -= difference
	else:
		ammo_loaded += ammo_left
		ammo_left = 0
	reloading = false
	_anim_ready()

func _anim_start():
	can_use = false
	if anim_player.has_animation(START_ANIM):
		anim_player.play(START_ANIM)
		await anim_player.animation_finished
	_anim_ready()

func _anim_ready():
	if anim_player.has_animation(READY_ANIM):
		anim_player.play(READY_ANIM)
		if anim_player.get_animation(READY_ANIM).get_loop_mode() == Animation.LOOP_NONE:
			await anim_player.animation_finished
	can_use = true

func _anim_shoot():
	can_use = false
	if anim_player.has_animation(SHOOT_ANIM):
		anim_player.play(SHOOT_ANIM)

func _anim_reload():
	can_use = false
	reloading = true
	timer.start(data.reload_time)
	if anim_player.has_animation(RELOAD_ANIM):
		anim_player.queue(RELOAD_ANIM)

func _anim_shutdown():
	can_use = false
	if anim_player.has_animation(READY_ANIM) and anim_player.has_animation(START_ANIM):
		anim_player.play_backwards(READY_ANIM)
		await anim_player.animation_finished
		anim_player.play_backwards(START_ANIM)
