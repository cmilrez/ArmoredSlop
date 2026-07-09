@abstract class_name Weapon extends Node3D

var timer: Timer = null
var anim_player: AnimationPlayer = null

@export var left_side := false:
	set(value):
		left_side = value
		scale.x = -1.0 if left_side else 1.0
var can_use := false
var reloading := false
var cooling := false

func _ready():
	timer = $Timer
	anim_player = $AnimationPlayer
	timer.one_shot = true

@abstract func activate(targeting: Targeting) -> void
@abstract func reload(manual_reload := false) -> void

func set_dmg_source(path: NodePath) -> void:
	var data = get('data')
	if data:
		data.damage_data.source = path
