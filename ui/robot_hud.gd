extends Control

@onready var armor_label = $Armor
@onready var h_box_container = $HBoxContainer

func update_armor_display(value: float):
	armor_label.text = '%.0f' % value

func update_ammo_display(value: int, id: int):
	var child: Label = h_box_container.get_child(id)
	child.text = str(value)
