extends VBoxContainer

@onready var game_manager : GameManager = get_node("../GameManager")
@onready var new_game : Button = get_node("NewGameButton")
@onready var abort : Button = get_node("AbortButton")


# Called when the node enters the scene tree for the first time.
func _ready():
	new_game.focus_mode = Control.FOCUS_NONE
	abort.focus_mode = Control.FOCUS_NONE

func _on_new_game_button_pressed():
	game_manager.end_game()
	game_manager.new_game()

func _on_abort_button_pressed():
	game_manager.end_game()
	get_tree().get_root().add_child(game_manager.menu_scene)
	get_tree().get_root().remove_child(get_node(".."))


func _on_undo_button_pressed():
	game_manager.undo()
