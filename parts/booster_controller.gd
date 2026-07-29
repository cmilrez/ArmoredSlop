extends Node

@export var character: Character = null
@export var list: Array[Booster] = []
var on_off := false:
	set(value):
		if not value == on_off:
			on_off = value
			toggle(on_off)

func _process(delta):
	on_off = character._boosting

func toggle(value: bool):
	for node in list:
		node.ignite(value)

func _on_builder_body_built(nodes):
	list.clear()
	for part in nodes:
		if part is Booster:
			list.append(part)
	toggle.call_deferred(on_off)
