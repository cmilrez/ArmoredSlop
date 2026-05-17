class_name Health extends Node

signal death

@export var data: CharacterData = null
var max_hp := 1.0
var hp := 1.0:
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
	var damage = damage_data.damage_bullet * 1.0 - (data.defense_bullet / 1000.0)
	damage += damage_data.damage_energy * 1.0 - (data.defense_energy / 1000.0)
	damage += damage_data.damage_explosive * 1.0 - (data.defense_explosive / 1000.0)
	hp -= damage
