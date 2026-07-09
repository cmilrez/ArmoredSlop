class_name Health extends Node

signal death
signal changed(value: float)

@export var data: CharacterData = null
var max_hp := 1.0
var hp := 1.0:
	set(value):
		if hp > 0.0 and value <= 0.0:
			death.emit()
		hp = minf(value, max_hp)
		changed.emit.call_deferred(hp)

func _ready():
	initialize.call_deferred()

func initialize():
	if data:
		max_hp = data.max_hp
	hp = max_hp

func take_damage(dmg_data: DamageData):
	var source = get_node_or_null(dmg_data.source)
	if source:
		if not source.team_group == Global.TEAM_C:
			if source.team_group == get_parent().team_group:
				return
	var damage = dmg_data.damage_bullet * data.defense_bullet
	damage += dmg_data.damage_energy * data.defense_energy
	damage += dmg_data.damage_explosive * data.defense_explosive
	hp -= damage
