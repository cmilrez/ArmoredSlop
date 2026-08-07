@abstract class_name BodyPartData extends PartData

@export var armor := 250.0
@export var bullet_defense := 250.0
@export var energy_defense := 250.0
@export var explosive_defense := 250.0
@export var bone_list: Dictionary[StringName, Array] = {} # {'bone_name': [Transform3D, ['children_names']]}
