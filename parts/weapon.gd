@abstract class_name Weapon extends Node3D

var timer: Timer = null
var anim_player: AnimationPlayer = null

var can_use := false
var reloading := false
var cooling := false

func _ready():
	timer = $Timer
	anim_player = $AnimationPlayer
	timer.one_shot = true

@abstract func activate(targeting: Targeting) -> void
@abstract func reload(manual_reload := false) -> void
