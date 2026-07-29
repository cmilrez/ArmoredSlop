extends AnimationTree

signal toggled_melee_hurtbox(enabled: bool)
signal melee_finished

const start_combo = &'parameters/Melee/conditions/start_combo'

@onready var robot: Robot = get_parent()

@export var anim_cancel := false
@export var melee_hurtbox := false:
	set(value):
		if not melee_hurtbox == value:
			toggled_melee_hurtbox.emit(value)
		melee_hurtbox = value
var blend := Vector2.ZERO
var move_angle := 0.0

func _ready():
	active = true
	get(&'parameters/playback').state_finished.connect(_on_state_finished)

func _process(delta):
	var weight = 1.0 - pow(0.5, delta * 16.0)
	var move_dir_2d = Vector2(robot.move_direction.x, robot.move_direction.z)
	
	blend = blend.lerp(move_dir_2d.rotated(robot.rotation.y).snappedf(1.0), weight)
	set('parameters/Airborne/Biped/blend_position', blend)
	set('parameters/Airborne/Quad/blend_position', blend)
	set('parameters/Boost/Biped/blend_position', blend)
	set('parameters/Boost/Tank/blend_position', blend)
	set('parameters/Boost/Quad/blend_position', blend)
	set('parameters/Ground/Biped/blend_position', blend)
	set('parameters/Ground/Quad/blend_position', blend)
	
	var blend2 = get('parameters/Ground/Tank/blend_position')
	if move_dir_2d:
		move_dir_2d = Vector2(move_dir_2d.y, move_dir_2d.x)
		var angle_diff = robot.rotation.y - move_dir_2d.angle() + PI
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
	var leg_type = get_parent().data.legs.leg_type
	match leg_type:
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
