extends AnimationTree

signal toggled_melee_hurtbox(enabled: bool)
signal melee_finished

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
	set('parameters/Melee/conditions/start_combo', true)

func _unhandled_input(event):
	if not anim_cancel: return
	var property = &'parameters/Melee/conditions/advance_combo'
	if get(property): return
	if event.is_action_pressed('arm_unit_right'):
		set(property, true)
		await get_tree().create_timer(0.5).timeout
		set(property, false)

func _on_state_finished(state: StringName):
	match state:
		&'Melee':
			melee_finished.emit()
		&'Melee_Start':
			set('parameters/Melee/conditions/start_combo', false)