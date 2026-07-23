extends Control

const y_offset := -50.0
@export var lock_on_data: LockOnData = null

func _ready():
	lock_on_data.changed.connect(queue_redraw)

func _draw():
	if not is_instance_valid(lock_on_data):
		return
	var center = get_viewport().get_visible_rect().size / 2.0
	var half_size = lock_on_data.region.size / 2.0
	lock_on_data.region.position = center - half_size
	lock_on_data.region.position.y += y_offset
	draw_rect(lock_on_data.region, Color.LIME_GREEN, false, 4.0)
