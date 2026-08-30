class_name Health extends Node

signal death
signal changed(new_hp: float)

@export var data: CharacterData = null
var max_hp := 1.0:
	set(value):
		max_hp = value
		if hp > max_hp:
			hp = max_hp
var hp := 1.0:
	set(value):
		var just_died = value <= 0.0 and hp > 0.0
		hp = minf(value, max_hp)
		if just_died:
			death.emit()
		changed.emit.call_deferred(hp)

func _ready():
	initialize.call_deferred()

func initialize() -> void:
	if data:
		max_hp = data.max_hp
	hp = max_hp

func refresh_values() -> void:
	max_hp = data.max_hp

func take_damage(dmg_data: DamageData) -> void:
	var source = get_node_or_null(dmg_data.source)
	if source:
		assert(source is Character3D)
		if get_parent().is_same_team(source.team):
			return
	var damage = dmg_data.kinetic_damage * data.bullet_defense
	damage += dmg_data.energy_damage * data.energy_defense
	damage += dmg_data.explosive_damage * data.explosive_defense
	hp -= damage
