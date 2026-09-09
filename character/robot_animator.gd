class_name RobotAnimator extends AnimationTree

signal toggled_melee_hurtbox(enabled: bool)
signal state_finished(state_name: StringName)

const START_COMBO = &'parameters/Melee/conditions/start_combo'

@onready var robot: Robot3D = get_parent()

@export var anim_cancel := false
@export var melee_hurtbox := false:
	set(value):
		if not melee_hurtbox == value:
			toggled_melee_hurtbox.emit(value)
		melee_hurtbox = value
var playback: AnimationNodeStateMachinePlayback
var blend := Vector2.ZERO

func _ready():
	playback = get(&'parameters/playback')
	playback.state_finished.connect(_on_playback_state_finished)
	active = true

func _process(delta):
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

func set_arm_recoil(right_arm: bool) -> void:
	set(&'parameters/ArmRecoil/conditions/right_arm', right_arm)
	set(&'parameters/ArmRecoil/conditions/left_arm', not right_arm)

func start_melee_attack() -> void:
	set(START_COMBO, true)

func _on_playback_state_finished(state: StringName):
	match state:
		&'Melee':
			set(START_COMBO, false)
			state_finished.emit(state)
		&'ArmRecoil':
			set(&'parameters/ArmRecoil/conditions/right_arm', false)
			set(&'parameters/ArmRecoil/conditions/left_arm', false)
			state_finished.emit(state)

func _on_builder_body_built(nodes):
	clear_caches()
	var leg_type = robot.data.legs.leg_type
	var request = ''
	match leg_type:
		LegsData.Type.BIPED:   request = 'Biped'
		LegsData.Type.REVERSE: request = 'Reverse'
		LegsData.Type.QUAD:    request = 'Quad'
		LegsData.Type.TANK:    request = 'Tank'
	set('parameters/Boost/LegType/transition_request', request)
	set('parameters/Ground/LegType/transition_request', request)
	set('parameters/Airborne/LegType/transition_request', request)
