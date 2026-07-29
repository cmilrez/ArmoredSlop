extends Robot

enum {WANDER, COMBAT}

@onready var action_timer = $ActionTimer
@onready var atk_timer = $AtkTimer

var action := WANDER: set=set_action
var home_position := Vector3.ZERO

func set_action(value):
	if not action == value:
		action = value
		atk_timer.stop()

func _ready():
	lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(self))
	lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(self))
	set_weapons(weapons.duplicate()) # xd
	set_deferred(&'home_position', global_position)

func _process(delta):
	if not alive:
		return
	if targeting.target:
		action = COMBAT
	else:
		action = WANDER
	%LookAtLegBase.active = not is_on_floor()
	match action:
		WANDER:
			if hor_distance(home_position) > 100.0:
				change_direction(hor_direction(home_position))
			elif action_timer.is_stopped():
				var new_dir = Vector3.FORWARD.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI)
				change_direction(new_dir)
				action_timer.start(maxf(5.0, 15.0 * randf()))
			var hor_vel = Vector2(velocity.z, velocity.x)
			if hor_vel:
				angle_y = hor_vel.angle() + PI
		COMBAT:
			var distance = hor_distance(targeting.position)
			var direction = hor_direction(targeting.position)
			if distance < 30.0:
				move_direction = -direction
			elif distance < 120.0:
				if action_timer.is_stopped():
					var new_dir = basis.x.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI)
					change_direction(new_dir)
					action_timer.start(maxf(3.0, 5.0 * randf()))
			else:
				move_direction = direction
			angle_y = Vector2(direction.z, direction.x).angle() + PI
			if atk_timer.is_stopped():
				weapons[0].activate(targeting)
				weapons[1].activate(targeting)
				atk_timer.start(maxf(0.3, 1.0 * randf()))
