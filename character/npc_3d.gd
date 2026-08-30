class_name NPC3D extends Character3D

@onready var tracker: Tracker3D = %Tracker3D

@export var data: NPCData = null

func _ready():
	lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(self))
	lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(self))
	var path = get_path()
	for weapon in weapons:
		weapon.set_dmg_source(path)
