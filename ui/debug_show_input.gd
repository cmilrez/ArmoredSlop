extends TextureRect

const MAX_COUNT = 5
var labels: Array[Label] = []
var marker: Label = null
var count := 0

func _ready():
	position = Vector2(6.0, 8.0)
	marker = Label.new()
	add_child(marker)
	marker.text = '>'
	marker.position.x = 8.0
	marker.modulate = Color.RED
	for i in range(MAX_COUNT):
		var new_label = Label.new()
		add_child(new_label)
		labels.append(new_label)
		new_label.position.x = 24.0
		new_label.position.y = i * 18.0
		new_label.modulate = Color.LIME_GREEN

func _input(event):
	if event is InputEventMouseMotion or event.is_echo() or event.is_released():
		return
	labels[count].text = event.as_text()
	marker.position.y = count * 18.0
	count += 1
	if count >= MAX_COUNT:
		count = 0
