class_name State extends Node

@export var transitions: Array[StateTransition] = []

func start(node: Node3D) -> void:
	pass

func exit(node: Node3D) -> void:
	pass

func update(node: Node3D, delta: float) -> void:
	pass

func physics_update(node: Node3D, delta: float) -> void:
	pass

func input_event(node: Node3D, event: InputEvent) -> void:
	pass

func key_input_event(node: Node3D, event: InputEvent) -> void:
	pass
