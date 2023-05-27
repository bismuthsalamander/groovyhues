extends Sprite2D


var grid_w : int = 9
var grid_h : int = 9
var tile_sz : Vector2 = Vector2(32, 32)

func _process(delta):
	pass

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos = get_local_mouse_position()
		var x = (pos.x)/ tile_sz.x
		var y = (pos.y)/ tile_sz.y
		var mouse_pos = get_global_mouse_position() - self.global_position
		print(mouse_pos)
		print(str("Mouse at ", get_global_mouse_position(), " mouse_pos ", mouse_pos))
		print(str(pos, " ", x, " ", y))
