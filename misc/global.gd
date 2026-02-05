extends Node

const TEAM_C = StringName('TeamC')
const QUARTER_PI = PI/4.0
const LARGE_9 = 999999999999.0

func _ready():
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	SignalBus.player_death.connect(_on_player_death)

func _input(event):
	if event.is_action_pressed('ui_cancel'):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_player_death():
	var fade := ColorRect.new()
	fade.color = Color.from_hsv(0.0, 0.0, 0.0, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().get_current_scene().add_child(fade)
	await create_tween().tween_property(fade, 'color', Color.BLACK, 5.0).finished
	var result := get_tree().reload_current_scene()
	if result != OK:
		print('Error reloading scene. ', result)

func push_rigid_body_3d(collision: KinematicCollision3D, velocity: Vector3, mass: float):
	var collider := collision.get_collider()
	if not collider is RigidBody3D:
		return
	var mass_ratio := minf(1.0, mass / collider.mass)
	if mass_ratio < 0.25:
		return
	var push_direction := -collision.get_normal()
	var velocity_difference: float = velocity.dot(push_direction) - collision.get_collider_velocity().dot(push_direction)
	if velocity_difference <= 0.0:
		return
	var collision_point := collision.get_position()
	var push_force := 10.0
	collider.apply_impulse(push_direction * velocity_difference * push_force, collision_point - collider.global_position)
