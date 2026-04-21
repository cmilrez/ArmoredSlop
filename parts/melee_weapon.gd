class_name MeleeWeapon extends Weapon

const START_ANIM = &'Start'
const READY_ANIM = &'Ready'
const PREPARE_ANIM = &'Prepare'
const ATTACK_ANIM = &'Attack'
const COOLDOWN_ANIM = &'Cooldown'

@onready var hurtbox = $Hurtbox
@export var data: MeleeWeaponData = null

func _ready():
	super._ready()
	timer.timeout.connect(func(): _anim_ready())
	_anim_start()

func activate(targeting: Targeting):
	if can_use:
		_anim_prepare()

func attack():
	_anim_attack()

func cooldown():
	_anim_cooldown()

func toggle_hurtbox(enabled: bool):
	hurtbox.monitoring = enabled
	hurtbox.monitorable = enabled

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
	cooling = false

func _anim_prepare():
	can_use = false
	if anim_player.has_animation(PREPARE_ANIM):
		anim_player.play(PREPARE_ANIM)

func _anim_attack():
	if anim_player.has_animation(ATTACK_ANIM):
		anim_player.play(ATTACK_ANIM)

func _anim_cooldown():
	can_use = false
	cooling = true
	timer.start(data.reload_time)
	if anim_player.has_animation(COOLDOWN_ANIM):
		anim_player.play(COOLDOWN_ANIM)

func _anim_shutdown(): # unused
	can_use = false
	if anim_player.has_animation(READY_ANIM) and anim_player.has_animation(START_ANIM):
		anim_player.play_backwards(READY_ANIM)
		await anim_player.animation_finished
		anim_player.play_backwards(START_ANIM)

func reload(manual_reload := false):
	return
