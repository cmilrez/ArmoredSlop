class_name Booster extends Node3D

@export var vfx: Node3D = null
var tween: Tween = null
var default_scale := Vector3.ONE
var duration := 0.0667

func _ready():
	if not vfx:
		vfx = self
	default_scale = vfx.scale
	show()

func ignite(value: bool):
	if tween:
		tween.kill()
	tween = create_tween()
	const PROP = ^'scale'
	if value:
		vfx.scale = Vector3.ZERO
		vfx.show()
		tween.tween_property(vfx, PROP, Vector3(3.0, 2.0, 3.0), duration)
		tween.tween_property(vfx, PROP, Vector3(4.0, 3.0, 4.0), duration)
		tween.tween_property(vfx, PROP, Vector3(3.0, 4.0, 3.0), duration)
		tween.tween_property(vfx, PROP, Vector3(2.0, 3.0, 2.0), duration)
		tween.tween_property(vfx, PROP, default_scale, duration)
	else:
		tween.tween_property(vfx, PROP, Vector3.ZERO, 0.2)
		tween.tween_callback(vfx.hide)
