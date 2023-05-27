extends Node2D

var top_left : Vector2
var origin: Vector2
var gtc : Transform2D

var tile_sz : Vector2 = Vector2(32, 32)
@onready var highlight = get_node("SelectedHighlight")

func _process(_delta):
	pass

func _ready():
	print("Board getting ready")
	gtc = get_global_transform_with_canvas()
	origin = gtc.origin
	var sprite = get_node("Background")
	top_left = origin - sprite.texture.get_size() / 2

func center_of_tile(idx):
	return (idx - Vector2(4, 4)) * tile_sz / Vector2(gtc.x.x, gtc.y.y)

func place_ball_at(b, idx):
	b.position = center_of_tile(idx)

func show_highlight_at(tile_pos : Vector2):
	highlight.position = center_of_tile(tile_pos)
	highlight.visible = true

func hide_highlight():
	highlight.visible = false
