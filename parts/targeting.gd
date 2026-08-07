class_name Targeting extends Marker3D

var lock_target := false
var target: Character = null:
	set(value):
		if lock_target:
			return
		target = value

func _ready():
	top_level = true

func _process(delta):
	if is_instance_valid(target):
		if not target.alive:
			target = null
			return
		position = target.get_lock_position()

func get_targeting_position(bullet_speed: float, bullet_position: Vector3) -> Vector3:
	if not is_instance_valid(target):
		return position
	var target_velocity = target.get_real_velocity()
	var target_velocity_length_squared = target_velocity.length_squared()
	if not target_velocity_length_squared:
		return position
	var target_position = position
	var time := 0.0
	# will never hit if slower
	if bullet_speed * bullet_speed > target_velocity_length_squared:
		var to_target = target_position - bullet_position
		if to_target:
			var a = bullet_speed * bullet_speed - target_velocity_length_squared
			var b = 2.0 * target_velocity.dot(to_target)
			var c = to_target.length_squared()
			time = (b + sqrt(b * b + 4.0 * a * c)) / (2.0 * a)
	return target_position + time * target_velocity
