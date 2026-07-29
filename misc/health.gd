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
		assert(source is Character)
		if get_parent().is_same_team(source.team):
			return
	var damage = dmg_data.bullet_damage * data.bullet_defense
	damage += dmg_data.energy_damage * data.energy_defense
	damage += dmg_data.explosive_damage * data.explosive_defense
	hp -= damage
