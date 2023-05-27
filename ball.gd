extends Sprite2D

class_name Ball

#TODO: move to global config class

var v : int
var pos : Vector2
var color : Color
var step_time : float = .1
@onready var mgr : Node2D = get_node("../../GameManager")
@onready var board : Node2D = get_node("../../BoardContainer")
var target : Vector2 = Vector2(-1, -1)
var path : Array = []
var until_next_jump : float = 0.0
var is_moving : bool = false
var step_start : Vector2
var step_dest : Vector2
var step_pct : float = 0.0

signal move_complete

func init(p, idx, manager):
	pos = p
	v = idx
	mgr = manager
	color = mgr.get_color_by_idx(v)
	self.modulate = color
	if mgr.is_wild(idx):
		texture = mgr.wild_texture

func finish_move():
	pos = target
	board.place_ball_at(self, pos)
	mgr.add_ball_to_grid(self, pos)
	move_complete.emit()
	#mgr.complete_move()

func begin_moving_to(tgt, via):
	path = via
	target = tgt
	mgr.remove_ball_from_grid(self, pos)
	#This is where we would begin animating the ball
	if Settings.animate_mode == Settings.ANIMATION_TYPE.NONE:
		finish_move()
	elif Settings.animate_mode == Settings.ANIMATION_TYPE.STEP:
		until_next_jump = 0.0
		is_moving = true
		return
	elif Settings.animate_mode == Settings.ANIMATION_TYPE.SMOOTH:
		step_pct = 0.0
		is_moving = true
		step_start = pos
		step_dest = path.pop_front()
		return

func _process(delta):
	if !is_moving:
		return
	if Settings.animate_mode == Settings.ANIMATION_TYPE.STEP:
		until_next_jump -= delta
		if until_next_jump <= 0.0:
			if path.size() == 0:
				is_moving = false
				finish_move()
				#mgr.add_ball_to_grid(self, target)
				#mgr.complete_move()
				return
			pos = path.pop_front()
			board.place_ball_at(self, pos)
			until_next_jump = step_time
	elif Settings.animate_mode == Settings.ANIMATION_TYPE.SMOOTH:
		step_pct = min(1.0, step_pct + (delta / step_time))
		pos = (step_start * (1 - step_pct)) + (step_dest * step_pct)
		board.place_ball_at(self, pos)
		if step_pct == 1.0:
			if path.is_empty():
				is_moving = false
				finish_move()
				return
			step_start = step_dest
			step_dest = path.pop_front()
			step_pct = 0.0

