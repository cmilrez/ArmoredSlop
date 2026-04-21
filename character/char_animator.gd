extends AnimationTree

signal toggled_melee_hurtbox(enabled: bool)
signal melee_finished

const advance_combo = &'parameters/Melee/conditions/advance_combo'
const start_combo = &'parameters/Melee/conditions/start_combo'

#@onready var playback: AnimationNodeStateMachinePlayback = get(&'parameters/playback')
@export var anim_cancel := false
@export var melee_hurtbox := false:
	set(value):
		if not melee_hurtbox == value:
			toggled_melee_hurtbox.emit(value)
		melee_hurtbox = value

func _ready():
	get(&'parameters/playback').state_finished.connect(_on_state_finished)
	get(&'parameters/Melee/playback').state_finished.connect(_on_state_finished)

func start_melee_attack():
	set(start_combo, true)

func _unhandled_input(event):
	if not anim_cancel: return
	if get(advance_combo): return
	if event.is_action_pressed('arm_unit_right'):
		set(advance_combo, true)
		await get_tree().create_timer(0.5).timeout
		set(advance_combo, false)

func _on_state_finished(state: StringName):
	match state:
		&'Melee':
			melee_finished.emit()
		&'Melee_Start':
			set(start_combo, false)
