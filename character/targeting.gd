class_name Targeting extends Marker3D

var target: Character = null: set=set_target

func _ready():
	top_level = true
	set_process(false)

func _process(delta):
	if not target.lock_on_marker.visible:
		target = null
		return
	global_position =  target.lock_on_marker.global_position

func set_target(new_target):
	if new_target is Node or new_target == null:
		target = new_target
	if new_target is DamageData:
		target = get_node(new_target.source)
	set_process(is_instance_valid(target))

func get_targeting_position(bullet_speed: float, bullet_position: Vector3) -> Vector3:
	if not is_instance_valid(target):
		return global_position
	var target_velocity := target.get_real_velocity()
	if not target_velocity:
		return global_position
	var target_position := global_position
	var time := 0.0
	if bullet_speed > target_velocity.length(): # too slow, will never hit
		var to_target := target_position - bullet_position
		if to_target:
			var a = bullet_speed * bullet_speed - target_velocity.length_squared()
			var b = 2.0 * target_velocity.dot(to_target)
			var c = to_target.length_squared()
			time = (b + sqrt(b * b + 4.0 * a * c)) / (2.0 * a)
	return target_position + time * target_velocity
