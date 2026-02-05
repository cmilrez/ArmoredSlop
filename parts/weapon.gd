class_name Weapon extends Node3D

@onready var timer = $Timer
@onready var anim_player = $AnimationPlayer

@export var spawners: Node3D = null
@export var data: WeaponData = null
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
var can_use := false
var ammo_empty := false
var reloading := false

func _ready():
	timer.timeout.connect(func (): if reloading: reload())
	ammo_loaded = data.clip_size
	ammo_left = data.ammo_max
	state_start()

func check_ammo() -> void:
	ammo_total = ammo_loaded + ammo_left
	if ammo_total <= 0 and not ammo_empty:
		ammo_empty = true
		state_shutdown()
	if ammo_total > 0 and ammo_empty:
		ammo_empty = false
		state_start()

func activate(targeting: Targeting) -> void:
	if not can_use:
		return
	state_shoot()
	var remaining_shots := spawners.get_child_count()
	for spawn: Node3D in spawners.get_children():
		if ammo_loaded <= 0:
			break
		remaining_shots -= 1
		var new_projectile: Node3D = data.projectile_scene.instantiate()
		var target_position = targeting.get_targeting_position(new_projectile.data.speed, spawn.global_position)
		add_child(new_projectile)
		new_projectile.global_position = spawn.global_position
		new_projectile.damage_data = data.damage_data
		new_projectile.look_at(target_position, Vector3.UP, true)
		ammo_loaded -= data.ammo_cost
		if data.multishot_interval > 0.0 and remaining_shots > 0:
			timer.start(data.multishot_interval)
			await timer.timeout
	if ammo_loaded <= 0:
		if ammo_left > 0 and not reloading:
			state_reload()
		return
	if data.shot_interval > 0.0:
		timer.start(data.shot_interval)
		await timer.timeout
	can_use = true

func reload(manual_reload := false) -> void:
	if ammo_left <= 0:
		reloading = false
		return
	var difference := data.clip_size - ammo_loaded
	if difference <= 0:
		return
	if manual_reload:
		if not reloading:
			state_reload()
		return
	if difference < ammo_left:
		ammo_loaded = data.clip_size
		ammo_left -= difference
	else:
		ammo_loaded += ammo_left
		ammo_left = 0
	reloading = false
	state_ready()

func state_start():
	can_use = false
	if anim_player.has_animation('Start'):
		anim_player.play('Start')
		await anim_player.animation_finished
	state_ready()

func state_ready():
	if anim_player.has_animation('Ready'):
		anim_player.play('Ready')
		if anim_player.get_animation('Ready').get_loop_mode() == Animation.LOOP_NONE:
			await anim_player.animation_finished
	can_use = true

func state_shoot():
	can_use = false
	if anim_player.has_animation('Shoot'):
		anim_player.play('Shoot')

func state_reload():
	can_use = false
	reloading = true
	timer.start(data.reload_time)
	if anim_player.has_animation('Reload'):
		anim_player.queue('Reload')

func state_shutdown():
	can_use = false
	if anim_player.has_animation('Ready') and anim_player.has_animation('Start'):
		anim_player.play_backwards('Ready')
		await anim_player.animation_finished
		anim_player.play_backwards('Start')
