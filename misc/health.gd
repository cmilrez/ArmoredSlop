class_name Health extends Node

signal death

@export var data: CharacterData = null
@export var max_hp := 1.0
@export var hp := 1.0:
	set(value):
		hp = minf(value, max_hp)
		if hp <= 0.0:
			death.emit()

func _ready():
	if data:
		max_hp = data.max_hp
	hp = max_hp

func take_damage(damage_data: DamageData):
	var source = get_node(damage_data.source)
	if source.is_in_group(Global.TEAM_C):
		hp -= damage_data.damage
		return
	if source.is_in_group(owner.team_group):
		return
	hp -= damage_data.damage
