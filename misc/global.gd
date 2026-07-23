extends Node

enum Teams {TEAM_A, TEAM_B, TEAM_C}

const QUARTER_PI := PI/4.0
const LARGE_FLOAT: float = 0x7FEFFFFFFFFFFFFF

func _ready():
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed('ui_cancel'):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func push_rigid_body_3d(collision: KinematicCollision3D, velocity: Vector3, mass: float):
	if not velocity:
		return
	var collider = collision.get_collider()
	if not collider is RigidBody3D:
		return
	var mass_ratio =  mass / collider.mass
	if mass_ratio < 0.25:
		return
	var push_direction = -collision.get_normal()
	var velocity_diff = velocity.dot(push_direction) - collision.get_collider_velocity().dot(push_direction)
	if velocity_diff <= 0.0:
		return
	var collision_point = collision.get_position()
	var push_force = mass * mass_ratio
	collider.apply_impulse(push_direction * velocity_diff * push_force, collision_point - collider.global_position)
