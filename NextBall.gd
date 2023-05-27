extends Sprite2D

class_name NextBall

var v : int
var color : Color
@onready var mgr : Node2D = get_node("../../GameManager")
@onready var board : Node2D = get_node("../../BoardContainer")

func set_val(val):
	v = val
	color = mgr.get_color_by_idx(v)
	self.modulate = color
	if mgr.is_wild(v):
		texture = mgr.wild_texture
	else:
		texture = mgr.ball_texture
