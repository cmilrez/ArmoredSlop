class_name StateTransition extends Resource

#@export var delay := 1.0
@export_node_path('State') var to_node := ^''
@export_node_path() var base_node := ^''
@export_custom(PROPERTY_HINT_EXPRESSION, '') var advance_expression: String = ''
var expression := Expression.new()

func evaluate_expression(node: Node) -> bool:
	if not advance_expression:
		return false
	var error = expression.parse(advance_expression)
	if not error == OK:
		push_warning(expression.get_error_text())
		return false
	var result = expression.execute([], node)
	if expression.has_execute_failed():
		push_warning(expression.get_error_text())
		return false
	return bool(result)
