extends Node2D

class_name Logger

enum EVENT_TYPE{SPAWN, MOVE, NEXT}
var events = []
var start_time = 0
var end_time = 0
var final_score = 0

const columns = "abcdefghi"
const rows = "987654321"

static func vec2coords(v : Vector2):
	return str(columns[v.x], rows[v.y])

static func coords2vec(s : String):
	if s.length() != 2:
		return null
	return Vector2(columns.find(s[0]), rows.find(s[1]))

var t : GameTranscript = GameTranscript.new()

class GameTranscript:
	var events = []
	var start_time = 0
	var end_time = 0
	var final_score = 0
	
	func _init():
		start_time = int(Time.get_unix_time_from_system())

	func add_event(e):
		events.append(e)
	
	func txt():
		var game_data = {
			"start_time": start_time,
			"end_time": end_time,
			"final_score": final_score,
			"events": []
		}
		for e in events:
				game_data['events'].append(e.str_rep())
		var out = JSON.stringify(game_data)
		return out
	
	func pop_last_turn():
		while self.events.size() > 0 && !(self.events.pop_back() is MoveEvent):
			pass
	
	func num_turns():
		var moves = self.events.filter(func(e): return e is MoveEvent)
		return moves.size()

	static func parse(raw_txt):
		var out = JSON.parse_string(raw_txt)
		print(raw_txt)
		print(out)
		if out == null:
			return null
		var result = GameTranscript.new()
		if "events" not in out or !out.events is Array:
			return null
		result.events = []
		for e in out.events:
			print(e)
			var evt = Event.from_string(e)
			if evt != null:
				result.events.append(evt)
			else:
				print(str("Could not parse event: ", e))
		result.start_time = out["start_time"]
		result.end_time = out["end_time"]
		result.final_score = out["final_score"]
		return result
	
class Event:
	static func from_string(s):
		var parts = s.split(" ")
		if parts[0] == "spawn":
			return SpawnEvent.from_string(s)
		elif parts[0] == "move":
			return MoveEvent.from_string(s)
		elif parts[0] == "next":
			return NextEvent.from_string(s)
		return null

	func execute(manager):
		pass

	func execute_fast(manager):
		self.execute(manager)

	func event_type():
		return null
	
	func str_rep():
		return null

class MoveEvent extends Event:
	var src : Vector2
	var dest : Vector2
	
	func _init(s : Vector2, d : Vector2):
		self.src = s
		self.dest = d
		
	func event_type():
		return EVENT_TYPE.MOVE
	
	func str_rep():
		return str("move ", Logger.vec2coords(src), " ", Logger.vec2coords(dest))

	func execute_fast(manager):
		print(str("FAST executing ", self.str_rep()))
		print(str("A ", manager.get_ball(src), " ", manager.get_ball(dest)))
		#var b = manager.get_ball(src)
		#manager.remove_ball(sc)
		manager.set_ball(dest, manager.get_ball(src))
		manager.set_ball(src, null)
		#manager.remove_ball(src)
		print(str("B ", manager.get_ball(src), " ", manager.get_ball(dest)))
		manager.eliminate_lines()
		print(str("C ", manager.get_ball(src), " ", manager.get_ball(dest)))

	func execute(manager):
		print(str("Executing ", self.str_rep()))
		manager.attempt_move(self.src, self.dest)

	static func from_string(s):
		var parts = s.split(" ")
		if parts.size() != 3 || parts[0] != "move":
			return null
		return MoveEvent.new(Logger.coords2vec(parts[1]), Logger.coords2vec(parts[2]))

class NextEvent extends Event:
	var color : int
	
	func _init(c : int):
		self.color = c
	
	func event_type():
		return EVENT_TYPE.NEXT
	
	func str_rep():
		return str("next ", color)
	
	func execute(manager):
		print(str("Executing ", self.str_rep()))
		manager.next_balls[manager.next_index].set_val(self.color)
		manager.next_index = (manager.next_index + 1) % manager.rules.spawn_per_turn

	static func from_string(s):
		var parts = s.split(" ")
		if parts.size() != 2 || parts[0] != "next":
			return null
		return NextEvent.new(int(parts[1]))

class SpawnEvent extends Event:
	var color : int
	var location : Vector2
	
	func _init(c : int, l : Vector2):
		self.color = c
		self.location = l

	func event_type():
		return EVENT_TYPE.SPAWN
	
	func str_rep():
		return str("spawn ", color, " ", Logger.vec2coords(location))
	
	func execute(manager):
		print(str("Executing ", self.str_rep()))
		manager.spawn_ball_at(self.location, self.color)

	static func from_string(s):
		var parts = s.split(" ")
		if parts.size() != 3 || parts[0] != "spawn":
			return null
		return SpawnEvent.new(int(parts[1]), Logger.coords2vec(parts[2]))

func start_log():
	t = GameTranscript.new()
	t.start_time = int(Time.get_unix_time_from_system())

func end_log():
	t.end_time = int(Time.get_unix_time_from_system())

func add_event(evt):
	t.add_event(evt)

func log_move(src, dest):
	t.add_event(MoveEvent.new(src, dest))

func log_next(color):
	t.add_event(NextEvent.new(color))

func log_spawn(color, location):
	t.add_event(SpawnEvent.new(color, location))

func set_score(s):
	t.final_score = s

func transcript():
	return t.txt()

func pop_last_turn():
	t.pop_last_turn()

func save_if_nonempty():
	if t.events.size() == 0:
		return
	var txt = transcript()
	var filepath = str("user://groovyhues_", t.start_time, "_", t.final_score, ".txt")
	var f = FileAccess.open(filepath, FileAccess.WRITE)
	f.store_string(txt)
	f.close()
