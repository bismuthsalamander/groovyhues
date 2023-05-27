extends Node

@onready var anim = get_node("MarginContainer/CenterContainer3/VBoxContainer/GridContainer/AnimationList")
@onready var wild = get_node("MarginContainer/CenterContainer3/VBoxContainer/GridContainer/WildList")
@onready var xxx = get_node("MarginContainer/CenterContainer3/VBoxContainer/GridContainer/WildList")

# Called when the node enters the scene tree for the first time.
func _ready():
	anim.selected = Settings.animate_mode
	wild.selected = 1 if Settings.use_wilds else 0

func _on_animation_list_item_selected(index):
	Settings.animate_mode = index

func _on_wild_list_item_selected(index):
	Settings.use_wilds = index == 1

func _on_close_button_pressed():
	self.visible = false

