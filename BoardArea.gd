extends Area2D

class_name BoardArea

var top_left : Vector2
var origin: Vector2
var gtc : Transform2D
var clicks_enabled : bool = true
@onready var board = get_node("../../BoardContainer")
@onready var mgr = get_node("../../GameManager")

func set_clicks_enabled(en):
	clicks_enabled = en and mgr.mode == mgr.GAME_MODE.PLAY

# Called when the node enters the scene tree for the first time.
func _ready():
	init_coordinates()
	get_viewport().connect("size_changed", _on_viewport_resize)

func init_coordinates():
	gtc = get_global_transform_with_canvas()
	origin = gtc.origin
	var sprite = get_node("../Background")
	top_left = origin - sprite.texture.get_size() / 2

func _on_viewport_resize():
	init_coordinates()

func _process(_delta):
	pass

func _on_input_event(_viewport, event, _shape_idx):
	if !clicks_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mpos = event.global_position
		var offset = mpos - top_left
		var tile = floor(offset / board.tile_sz)
		print(str("Click at ", tile, " ", Time.get_ticks_usec()))
		mgr.click_tile(tile)
		#show_highlight_at(tile)
		#highlight.visible = false
		#var gpos = global_position
		#print(str("Gpos: ", gpos))
		#print(str("Lpos: ", local_position))
		#print(str("Evpos: ", event.global_position))
		#var pos = get_local_mouse_position()
		#var x = (pos.x)/ tile_sz.x
		#var y = (pos.y)/ tile_sz.y
		#var mouse_pos = get_global_mouse_position() - self.global_position
		#print(mouse_pos)
		#print(str("Mouse at ", get_global_mouse_position(), " mouse_pos ", mouse_pos))
		#print(str(pos, " ", x, " ", y))
		#print(str("Top left: ", top_left))
