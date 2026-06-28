class_name NPC extends Character

@onready var targeting = %Targeting

func _ready():
	lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(self))
	lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(self))
	var path = get_path()
	for weapon in weapons:
		weapon.damage_data = weapon.damage_data.duplicate()
		weapon.damage_data.source = path

func _physics_process(delta):
	if alive:
		for i in get_slide_collision_count():
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	move_and_slide()
