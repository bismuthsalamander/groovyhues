extends Node2D

class_name GameManager

var menu_scene

# NODES AND RESOURCES
@onready var board_area : BoardArea = get_node("../BoardContainer/BoardArea")
@onready var board = get_node("../BoardContainer")
@onready var scoreboard : Label = get_node("../Scoreboard")
@onready var game_over_display : Node2D = get_node("../GameOverDisplay")
@onready var wild_texture = load("res://Sprites/wildball.png")
@onready var ball_texture = load("res://Sprites/ball.png")
@onready var logger = get_node("../Logger")

enum GAME_MODE{PLAY, REVIEW}

var next_balls : Array[NextBall] = []
var ball_scene = preload("res://ball.tscn")
@export var colors : Array[Color]

# GAME RULES
var rules = GameRules.default()

# REPLAY
var mode = GAME_MODE.PLAY
var replay_transcript
var num_turns : int
var current_turn : int = 0
var current_event : int = 0
var next_index : int = 0

# GAME STATE
var score : int = 0
var grid : Array
var NULL_SELECTION = Vector2(-1, -1)
var selected : Vector2 = NULL_SELECTION
var pending_from : Vector2
var pending_to : Vector2
var game_live : bool = true
var undo_stack : Array = []

class GameRules:
	var grid_sz : Vector2
	var num_colors : int
	var init_balls : int
	var min_line_length : int
	var spawn_per_turn : int
	static func default():
		return GameRules.new(Vector2(9, 9), 7, 5, 5, 3)

	func _init(_grid_sz : Vector2, _num_colors : int, _init_balls : int, _min_line_length : int, _spawn_per_turn : int):
		self.grid_sz = _grid_sz
		self.num_colors = num_colors
		self.init_balls = _init_balls
		self.min_line_length = _min_line_length
		self.spawn_per_turn = _spawn_per_turn

class GameState:
	var grid : Array
	var next : Array
	var score : int
	var rules : GameRules
	var game_live : bool
	
	func _init(_rules : GameRules):
		self.rules = _rules
		self.grid = GameManager.new_grid(rules.grid_sz)
		self.next = []
		self.game_live = true

func serialize_state():
	var s = GameState.new(rules)
	for r in self.grid.size():
		for c in self.grid[r].size():
			s.grid[r][c] = val_at(Vector2(c, r))
	for n in next_balls:
		s.next.append(n.v)
	s.score = score
	return s

func val_at(idx):
	var b = get_ball(idx)
	if b == null:
		return b
	return b.v

func get_ball(idx):
	if !is_valid_pos(idx) || idx.y >= grid.size() || idx.x >= grid[idx.y].size():
		return null
	return grid[idx.y][idx.x]

func set_ball(idx, val):
	if !is_valid_pos(idx) || idx.y >= grid.size() || idx.x >= grid[idx.y].size():
		return null
	grid[idx.y][idx.x] = val

func is_occupied(idx):
	return get_ball(idx) != null

func is_empty(idx):
	return !is_occupied(idx)

func get_color_by_idx(color_idx):
	return colors[color_idx]

func is_something_selected():
	return selected != NULL_SELECTION
	
func is_nothing_selected():
	return !is_something_selected()

func select_tile(idx):
	selected = idx
	board.show_highlight_at(idx)

func clear_selection():
	selected = NULL_SELECTION
	board.hide_highlight()

func remove_ball_from_grid(ball, idx):
	assert(get_ball(idx) == ball, str("Ball ", ball.v, " attempted to remove self from incorrect position ", idx))
	set_ball(idx, null)

func add_ball_to_grid(ball, idx):
	if is_occupied(idx):
		print(str("Error: cannot add ball ", ball, " to ", idx, " because that cell is occupied by ", ball))
		return
	set_ball(idx, ball)

func spawn_ball_at(pos, c):
	logger.log_spawn(c, pos)
	add_ball_at(pos, c)

func add_ball_at(pos, c):
	var b = ball_scene.instantiate()
	#b.mgr = self
	b.init(pos, c, self)
	b.move_complete.connect(complete_move)
	set_ball(pos, b)
	board.add_child(b)
	board.place_ball_at(b, pos)	

func generate_new_nexts():
	for i in next_balls.size():
		var idx = random_color_idx()
		next_balls[i].set_val(idx)
		logger.log_next(idx)

# Called when the node enters the scene tree for the first time.
func _ready():
	next_balls.append(get_node("../NextDisplay/NextBall"))
	next_balls.append(get_node("../NextDisplay/NextBall2"))
	next_balls.append(get_node("../NextDisplay/NextBall3"))
	new_game()

func load_transcript(t):
	print("Loading transcript - here's the current board")
	print_board()
	mode = GAME_MODE.REVIEW
	replay_transcript = t
	get_node("../GameReviewContainer").visible = true
	board_area.set_clicks_enabled(false)
	score = 0
	update_scoreboard()
	current_turn = 0
	current_event = 0
	num_turns = replay_transcript.num_turns()
	update_turn_counter()
	update_review_controls_enabled(true)
	remove_all_balls()
	while !(replay_transcript.events[current_event] is Logger.MoveEvent):
		replay_transcript.events[current_event].execute(self)
		current_event += 1

func control_disabled(ctrl, dis):
	if dis:
		ctrl.release_focus()
	ctrl.disabled = dis

func update_review_controls_enabled(en):
	print(str("Updating revie controls: ", en))
	control_disabled(get_node("../GameReviewContainer/ControlBox/BackToStart"), !en || current_turn == 0)
	control_disabled(get_node("../GameReviewContainer/ControlBox/Back"), !en || current_turn == 0)
	control_disabled(get_node("../GameReviewContainer/ControlBox/Next"), !en || current_turn == num_turns)
	control_disabled(get_node("../GameReviewContainer/ControlBox/NextToEnd"), !en || current_turn == num_turns)
	
func update_turn_counter():
	get_node("../GameReviewContainer/ControlBox/Label").text = str(current_turn, " / ", num_turns)

func new_game():
	mode = GAME_MODE.PLAY
	get_node("../GameReviewContainer").visible = false
	remove_all_balls()
	grid = new_grid(rules.grid_sz)
	logger.start_log()
	score = 0
	update_scoreboard()
	for i in rules.init_balls:
		spawn_ball_at(random_open_position(), random_color_idx())
	generate_new_nexts()
	game_over_display.visible = false
	board_area.set_clicks_enabled(true)
	undo_stack = []
	update_undo_visibility()

static func new_grid(sz, default=null):
	var g = []
	for r in sz.y:
		g.append([])
		for c in sz.x:
			g[r].append(default)
	return g

func random_color_idx():
	var max_idx = colors.size() - 1 if Settings.use_wilds else colors.size() - 2
	return randi_range(0, max_idx)

func is_wild(idx):
	return idx == colors.size() - 1

func random_open_position():
	#We'll make this work in linear time
	var open_cells = []
	for r in rules.grid_sz.y:
		for c in rules.grid_sz.x:
			var pos = Vector2(c, r)
			if is_empty(pos):
				open_cells.append(pos)
	if open_cells.size() == 0:
		return null
	return open_cells[randi_range(0, open_cells.size() - 1)]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func is_valid_pos(pos):
	return 	pos.x >= 0 && \
			pos.y >= 0 && \
			pos.x < rules.grid_sz.x && \
			pos.y < rules.grid_sz.y

func open_neighbors_of(idx):
	var result = []
	var deltas = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	for d in deltas:
		var n = idx + d
		if is_valid_pos(n) && is_empty(n):
			result.append(n)
	return result
			
func grid_path(from, to):
	var timestamp_start = Time.get_ticks_usec()
	var distances = new_grid(rules.grid_sz, -1)
	var parents = new_grid(rules.grid_sz, null)
	var cur_dist = 1
	distances[from.y][from.x] = 0
	var frontier = [from]
	while frontier.size() > 0:
		var new_frontier = []
		for f in frontier:
			var my_neighbors = open_neighbors_of(f)
			for nn in my_neighbors:
				if distances[nn.y][nn.x] != -1:
					continue
				distances[nn.y][nn.x] = cur_dist
				parents[nn.y][nn.x] = f
				new_frontier.append(nn)
		frontier = new_frontier
		cur_dist += 1
	var timestamp_end = Time.get_ticks_usec()
	print(str("Time to complete: ", timestamp_end - timestamp_start, "(",timestamp_start," - ", timestamp_end, ")"))
	if parents[to.y][to.x] == null:
		return null
	var result = []
	var cpos = to
	while true:
		result.push_front(cpos)
		if cpos == from:
			break
		cpos = parents[cpos.y][cpos.x]
	return result

func print_board():
	print("Here's the board")
	for r in rules.grid_sz.y:
		var row = ""
		for c in rules.grid_sz.x:
			var val = val_at(Vector2(c, r))
			if val == null:
				row += " "
			else:
				row += str(val)
		print(row)

func print_board_nulls():
	print("Here's the board")
	for r in rules.grid_sz.y:
		var row = ""
		for c in rules.grid_sz.x:
			var ball = get_ball(Vector2(c, r))
			if ball == null:
				row += " "
			else:
				row += "X"
		print(row)

func click_tile(idx):
	if is_nothing_selected():
		if is_occupied(idx):
			select_tile(idx)
	elif idx == selected:
		clear_selection()
	elif is_occupied(idx):
		select_tile(idx)
	else:
		attempt_move(selected, idx)

func save_undo_state():
	undo_stack.append(serialize_state())

func attempt_move(src, dest):
	var mypath = grid_path(src, dest)
	if mypath == null:
		return
	if mode == GAME_MODE.PLAY:
		undo_stack = []
	update_undo_visibility()
	move(src, dest, mypath)

func update_undo_visibility():
	get_node("../ControlButtons/UndoButton").visible = undo_stack.size() > 0 and mode == GAME_MODE.PLAY
	
func apply_state(s):
	# delete all balls
	remove_all_balls()
	for r in rules.grid_sz.y:
		for c in rules.grid_sz.x:
			if s.grid[r][c] != null:
				add_ball_at(Vector2(c, r), s.grid[r][c])
	# set grid and generate balls
	for i in s.next.size():
		next_balls[i].set_val(s.next[i])
	score = s.score
	update_scoreboard()
	game_live = s.game_live
	board_area.set_clicks_enabled(game_live)
	game_over_display.visible = !game_live
	pass
	
func undo():
	if undo_stack.size() <= 0:
		return
	var new_state = undo_stack.pop_back()
	apply_state(new_state)
	clear_selection()
	logger.pop_last_turn()

func move(from, to, path):
	save_undo_state()
	pending_from = from
	pending_to = to
	board_area.set_clicks_enabled(false)
	update_review_controls_enabled(false)
	get_ball(from).begin_moving_to(to, path)
	logger.log_move(pending_from, pending_to)
	clear_selection()

func colors_match(a, b):
	return is_wild(a) || is_wild(b) || a == b

func eliminate_lines():
	var all_lines = []
	var to_eliminate = []
	var deltas = [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 1)]
	
	for delta in deltas:
		var current_indexes = []
		for r in rules.grid_sz.y:
			for c in rules.grid_sz.x:
				var start = Vector2(c, r)
				var line_color = val_at(start)
				if val_at(start) == null || (current_indexes.find(start) != -1 && !is_wild(val_at(start))):
					continue
				var my_indexes = [start]
				var check_pos = start + delta
				while is_valid_pos(check_pos) && val_at(check_pos) != null && colors_match(val_at(check_pos), line_color):
					my_indexes.append(check_pos)
					if is_wild(line_color):
						line_color = val_at(check_pos)
					check_pos += delta
					
				if my_indexes.size() >= rules.min_line_length:
					print(str("Line color ", line_color, " @ ", start, " dir ", delta, " len ", my_indexes.size(), " (>= ", rules.min_line_length, ")"))
					current_indexes += my_indexes
					all_lines.append(my_indexes)
		to_eliminate += current_indexes
					
	for idx in to_eliminate:
		print(str("Line eliminates ", idx, " ", get_ball(idx)))
		remove_ball(idx)
		print(str("Just eliminated ", idx, " ", get_ball(idx)))
	for line in all_lines:
		increase_score(score_for_line(line))
	return to_eliminate.size() > 0

func increase_score(amt):
	score += amt
	logger.set_score(score)
	update_scoreboard()
	
func update_scoreboard():
	scoreboard.text = str("Score: ", score)

func score_for_line(line):
	return line.size()

func remove_all_balls():
	print_board_nulls()
	for r in rules.grid_sz.y:
		for c in rules.grid_sz.x:
			remove_ball(Vector2(c, r))

func remove_ball(idx):
	var b = get_ball(idx)
	set_ball(idx, null)
	if b != null:
		b.queue_free()
	assert(get_ball(idx) == null)

#todo: track count
func board_is_full():
	for r in rules.grid_sz.y:
		for c in rules.grid_sz.x:
			if val_at(Vector2(c, r)) == null:
				return false
	return true
	
func complete_move():
	print("Move is complete!")
	board_area.set_clicks_enabled(true)
	update_undo_visibility()
	var had_match = eliminate_lines()
	if !had_match && mode == GAME_MODE.PLAY:
		spawn_nexts()
		eliminate_lines()
		if board_is_full():
			player_lost()
	if mode == GAME_MODE.REVIEW:
		current_turn += 1
		current_event += 1
		update_turn_counter()
		execute_until_next_move()
		update_review_controls_enabled(true)

func spawn_nexts():
	for i in next_balls.size():
		var p = random_open_position()
		if p != null:
			spawn_ball_at(p, next_balls[i].v)
			eliminate_lines()
		else:
			return false
	generate_new_nexts()
	return true

func player_lost():
	game_over_display.visible = true
	end_game()

func end_game():
	game_live = false
	board_area.set_clicks_enabled(false)
	logger.end_log()
	if mode == GAME_MODE.PLAY:
		logger.save_if_nonempty()



func _on_back_to_start_pressed():
	print("Clearing board for back to start")
	print_board()
	remove_all_balls()
	load_transcript(replay_transcript)

func _on_back_pressed():
	if current_turn == 0:
		return
	current_turn -= 1
	current_event -= 1
	while !(replay_transcript.events[current_event] is Logger.MoveEvent):
		current_event -= 1
	undo()
	update_turn_counter()
	update_review_controls_enabled(true)

func _on_next_pressed():
	replay_transcript.events[current_event].execute(self)
	print_board()

func execute_until_next_move():
	while current_event < replay_transcript.events.size() && !(replay_transcript.events[current_event] is Logger.MoveEvent):
		replay_transcript.events[current_event].execute(self)
		current_event += 1

func _on_next_to_end_pressed():
	while current_event < replay_transcript.events.size():
		print("JUMPING")
		var evt = replay_transcript.events[current_event]
		if evt is Logger.MoveEvent:
			save_undo_state()
			current_turn += 1
		evt.execute_fast(self)
		current_event += 1
		print_board_nulls()
	#urrent_turn = num_turns
	update_review_controls_enabled(true)
	update_turn_counter()
	print_board()
	print("JUMPING IS DONE")
	print_board_nulls()


func _on_button_pressed():
	print_board_nulls()
