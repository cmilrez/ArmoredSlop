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
	#var playback: AnimationNodeStateMachinePlayback = get(&'parameters/playback')
	#print(playback.get_current_node())
	
	var weight = exp(-8 * delta)
	var move_dir_2d = Vector2(robot.move_direction.x, robot.move_direction.z)
	
	blend = move_dir_2d.rotated(robot.rotation.y).round().lerp(blend, weight)
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
		blend2 = Vector2.UP.rotated(angle_diff).lerp(blend2, weight)
		set('parameters/Ground/Tank/blend_position', blend2)
	else:
		set('parameters/Ground/Tank/blend_position', Vector2.ZERO.lerp(blend2, weight))

func start_melee_attack():
	set(start_combo, true)

func _on_state_finished(state: StringName):
	match state:
		&'Melee':
			set(start_combo, false)
			melee_finished.emit()

func _on_builder_body_built(nodes):
	var leg_type = robot.data.legs.leg_type
	var request = ''
	match leg_type:
		LegsData.Type.BIPED:
			request = 'Biped'
		LegsData.Type.REVERSE:
			request = 'Reverse'
		LegsData.Type.QUAD:
			request = 'Quad'
		LegsData.Type.TANK:
			request = 'Tank'
	set('parameters/Boost/LegType/transition_request', request)
	set('parameters/Ground/LegType/transition_request', request)
	set('parameters/Airborne/LegType/transition_request', request)
