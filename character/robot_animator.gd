extends AnimationTree

signal toggled_melee_hurtbox(enabled: bool)
signal melee_finished

const start_combo = &'parameters/Melee/conditions/start_combo'

@export var anim_cancel := false
@export var melee_hurtbox := false:
	set(value):
		if not melee_hurtbox == value:
			toggled_melee_hurtbox.emit(value)
		melee_hurtbox = value
var blend := Vector2.ZERO
var blend_target := Vector2.ZERO
var move_angle := 0.0

func _ready():
	active = true
	get(&'parameters/playback').state_finished.connect(_on_state_finished)

func _process(delta):
	var weight = 1.0 - pow(0.5, delta * 16.0)
	blend = blend.lerp(blend_target, weight)
	set('parameters/Airborne/Biped/blend_position', blend)
	set('parameters/Airborne/Quad/blend_position', blend)
	set('parameters/Boost/Biped/blend_position', blend)
	set('parameters/Boost/Tank/blend_position', blend)
	set('parameters/Boost/Quad/blend_position', blend)
	set('parameters/Ground/Biped/blend_position', blend)
	set('parameters/Ground/Quad/blend_position', blend)
	var blend2 = get('parameters/Ground/Tank/blend_position')
	if blend_target:
		var angle_diff = get_parent().rotation.y - move_angle
		blend2 = blend2.lerp(Vector2.UP.rotated(angle_diff), weight)
		set('parameters/Ground/Tank/blend_position', blend2)
	else:
		set('parameters/Ground/Tank/blend_position', blend2.lerp(Vector2.ZERO, weight))

func start_melee_attack():
	set(start_combo, true)

func _on_state_finished(state: StringName):
	match state:
		&'Melee':
			set(start_combo, false)
			melee_finished.emit()

func _on_builder_body_built(nodes):
	for part in nodes:
		var data = part.data
		if data is LegsData:
			match data.leg_type:
				LegsData.Type.BIPED:
					set('parameters/Boost/LegType/transition_request', 'Biped')
					set('parameters/Ground/LegType/transition_request', 'Biped')
					set('parameters/Airborne/LegType/transition_request', 'Biped')
				LegsData.Type.REVERSE:
					set('parameters/Boost/LegType/transition_request', 'Reverse')
					set('parameters/Ground/LegType/transition_request', 'Reverse')
					set('parameters/Airborne/LegType/transition_request', 'Reverse')
				LegsData.Type.QUAD:
					set('parameters/Boost/LegType/transition_request', 'Quad')
					set('parameters/Ground/LegType/transition_request', 'Quad')
					set('parameters/Airborne/LegType/transition_request', 'Quad')
				LegsData.Type.TANK:
					set('parameters/Boost/LegType/transition_request', 'Tank')
					set('parameters/Ground/LegType/transition_request', 'Tank')
					set('parameters/Airborne/LegType/transition_request', 'Tank')
			return
