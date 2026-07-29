class_name MeleeWeapon extends Weapon

const START_ANIM = &'Start'
const READY_ANIM = &'Ready'
const PREPARE_ANIM = &'Prepare'
const ATTACK_ANIM = &'Attack'
const COOLDOWN_ANIM = &'Cooldown'

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var hurtbox = $Hurtbox

@export var param: MeleeWeaponParam = null

func _ready():
	recoil = true
	timer.timeout.connect(_state_ready)
	param = param.duplicate()
	hurtbox.damage_data = param.damage_data
	toggle_hurtbox(false)
	_state_start()

func activate(targeting: Targeting) -> void:
	if can_use:
		_state_prepare()

func set_dmg_source(path: NodePath) -> void:
	if param.damage_data:
		param.damage_data.source = path

func reload(manual_reload := false) -> void:
	return

func attack() -> void:
	_state_attack()

func cooldown() -> void:
	_state_cooldown()

func toggle_hurtbox(enabled: bool) -> void:
	hurtbox.monitoring = enabled
	hurtbox.monitorable = enabled

func _state_start() -> void:
	can_use = false
	if anim_player.has_animation(START_ANIM):
		anim_player.play(START_ANIM)
		await anim_player.animation_finished
	_state_ready()

func _state_ready() -> void:
	if anim_player.has_animation(READY_ANIM):
		anim_player.play(READY_ANIM)
		if anim_player.get_animation(READY_ANIM).get_loop_mode() == Animation.LOOP_NONE:
			await anim_player.animation_finished
	can_use = true
	cooling = false

func _state_prepare() -> void:
	can_use = false
	if anim_player.has_animation(PREPARE_ANIM):
		anim_player.play(PREPARE_ANIM)

func _state_attack() -> void:
	if anim_player.has_animation(ATTACK_ANIM):
		anim_player.play(ATTACK_ANIM)

func _state_cooldown() -> void:
	can_use = false
	cooling = true
	timer.start(param.reload_time)
	if anim_player.has_animation(COOLDOWN_ANIM):
		anim_player.play(COOLDOWN_ANIM)

#func _state_shutdown() -> void: # unused
	#can_use = false
	#if anim_player.has_animation(READY_ANIM) and anim_player.has_animation(START_ANIM):
		#anim_player.play_backwards(READY_ANIM)
		#await anim_player.animation_finished
		#anim_player.play_backwards(START_ANIM)
