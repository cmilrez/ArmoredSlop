extends Control

@export var param: LockOnParamenters = null

func _ready():
	param.changed.connect(queue_redraw)

func _draw():
	if not is_instance_valid(param):
		return
	var center = get_viewport().get_visible_rect().size / 2.0
	var half_size = param.aim_rect.size / 2.0
	param.aim_rect.position = center - half_size
	param.aim_rect.position += param.aim_rect_offset
	draw_rect(param.aim_rect, Color.LIME_GREEN, false, 4.0)
