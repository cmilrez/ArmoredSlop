class_name StateMachine extends Node

@export var base_node: Node
@export var state: State: set = set_state
var prev_state: State

func _ready():
	if not state:
		state = get_child(0)

func _process(delta):
	check_transition()
	state.update(base_node, delta)

func _physics_process(delta):
	state.physics_update(base_node, delta)

func _unhandled_input(event):
	state.input_event(base_node, event)

func _unhandled_key_input(event):
	state.key_input_event(base_node, event)

func check_transition():
	for transition: StateTransition in state.transitions:
		if transition.evaluate_expression(base_node):
			if transition.to_node:
				state = state.get_node(transition.to_node)
			else:
				state = prev_state

func set_state(new_state: State):
	if not is_instance_valid(new_state):
		push_warning('State node invalid: ', new_state)
		return
	if new_state == state:
		return
	prev_state = state
	state = new_state
	if is_instance_valid(prev_state):
		prev_state.exit(base_node)
	state.start(base_node)

func set_state_node_path(state_path: NodePath):
	set_state(get_node(state_path))
