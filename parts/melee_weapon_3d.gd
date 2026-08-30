class_name MeleeWeapon3D extends Weapon3D

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
	timer.one_shot = true
	timer.timeout.connect(_state_ready)
	var dmg_data = DamageData.new()
	dmg_data.kinetic_damage = param.kinetic_damage
	dmg_data.energy_damage = param.energy_damage
	dmg_data.explosive_damage = param.explosive_damage
	hurtbox.damage_data = dmg_data
	toggle_hurtbox(false)
	_state_ready()

func activate(targets: Array[Character3D] = [], aim_position := Vector3.ZERO) -> void:
	if can_use:
		_state_prepare()

func set_dmg_source(path: NodePath) -> void:
	if hurtbox.damage_data:
		hurtbox.damage_data.source = path

func reload(manual_reload := false) -> void:
	return

func attack() -> void:
	_state_attack()

func cooldown() -> void:
	_state_cooldown()

func toggle_hurtbox(enabled: bool) -> void:
	hurtbox.monitoring = enabled
	hurtbox.monitorable = enabled

func _state_ready() -> void:
	if anim_player.has_animation(READY_ANIM):
		anim_player.play(READY_ANIM)
		if anim_player.get_animation(READY_ANIM).get_loop_mode() == Animation.LOOP_NONE:
			await anim_player.animation_finished
	can_use = true
	reloading = false

func _state_prepare() -> void:
	can_use = false
	if anim_player.has_animation(PREPARE_ANIM):
		anim_player.play(PREPARE_ANIM)

func _state_attack() -> void:
	if anim_player.has_animation(ATTACK_ANIM):
		anim_player.play(ATTACK_ANIM)

func _state_cooldown() -> void:
	can_use = false
	reloading = true
	timer.start(param.reload_time)
	if anim_player.has_animation(COOLDOWN_ANIM):
		anim_player.play(COOLDOWN_ANIM)
