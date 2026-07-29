@abstract class_name Weapon extends Node3D

@export var recoil := false
@export var left_side := false:
	set(value):
		left_side = value
		scale.x = -1.0 if left_side else 1.0
var can_use := false
var reloading := false
var cooling := false

@abstract func activate(targeting: Targeting) -> void
@abstract func set_dmg_source(path: NodePath) -> void
@abstract func reload(manual_reload := false) -> void
