extends TextureRect

var labels: Array[Label] = [null, null, null, null, null]
var mark: Label = null
var count := 0

func _ready():
	position = Vector2(6.0, 8.0)
	mark = Label.new()
	add_child(mark)
	mark.text = '>'
	mark.position.x = 8.0
	mark.modulate = Color.RED

func _input(event):
	if event is InputEventMouseMotion or event.is_echo() or event.is_released():
		return
	if count > 4:
		count = 0
	var new_label = Label.new()
	if is_instance_valid(labels[count]):
		labels[count].free()
	labels[count] = new_label
	add_child(new_label)
	new_label.text = event.as_text()
	new_label.position.x = 24.0
	new_label.position.y = count * 18.0
	new_label.modulate = Color.LIME_GREEN
	mark.position.y = count * 18.0
	count += 1
