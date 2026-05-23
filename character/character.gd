class_name Character extends CharacterBody3D

@export var data: CharacterData = null
@export var mass := 40.0
@export_enum('TeamA', 'TeamB', 'TeamC') var team_group := 'TeamC':
	set(value):
		remove_from_group(team_group)
		add_to_group(value)
		team_group = value
@export var lock_on_marker: Node3D = null
@export var alive := true

var move_direction := Vector3.ZERO
var gravity := Vector3.ZERO

func get_lock_position() -> Vector3:
	return lock_on_marker.global_position
