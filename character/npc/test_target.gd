extends Character

@export var follow: PathFollow3D = null
@export var speed := 40.0

func _ready():
	lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(self))
	lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(self))
	global_position = follow.global_position

func _physics_process(delta):
	follow.progress += speed * delta
	velocity = (follow.global_position - global_position) / delta
	move_and_slide()
