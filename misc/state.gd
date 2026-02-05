class_name State extends Node

@export var transitions: Array[StateTransition] = []

func start(node: Node) -> void:
	pass

func exit(node: Node) -> void:
	pass

func update(node: Node, delta: float) -> void:
	pass

func physics_update(node: Node, delta: float) -> void:
	pass

func input_event(node: Node, event: InputEvent) -> void:
	pass

func key_input_event(node: Node, event: InputEvent) -> void:
	pass
