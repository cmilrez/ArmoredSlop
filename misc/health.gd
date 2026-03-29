class_name Health extends Node

signal death

@export var data: CharacterData = null
@export var max_hp := 1.0
@export var hp := 1.0:
	set(value):
		if hp > 0.0 and value <= 0.0:
			death.emit()
		hp = minf(value, max_hp)

func _ready():
	if data:
		max_hp = data.max_hp
	hp = max_hp

func take_damage(damage_data: DamageData):
	if not damage_data:
		return
	var source = get_node_or_null(damage_data.source)
	if source:
		if not source.is_in_group(Global.TEAM_C):
			if source.is_in_group(owner.team_group):
				return
	hp -= damage_data.damage
