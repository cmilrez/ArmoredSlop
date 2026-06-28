class_name NPCData extends CharacterData

@export_range(0.0, 60.0, 0.001, 'or_greater', 'suffix:s') var atention_spam := 5.0
@export_range(0.0, 100.0, 0.001, 'or_greater', 'suffix:m') var distance_max := 100.0
@export_range(-180.0, 180.0, 0.001, 'radians_as_degrees') var fov := Global.QUARTER_PI
