extends Node

var main = preload("res://main.tscn").instantiate()
var mgr = main.get_node("GameManager")
@onready var menu = get_tree().get_root().get_node("/root/Main")

func _ready():
	mgr.menu_scene = menu
	get_node("LoadTranscript").file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	get_node("LoadTranscript").access = FileDialog.Access.ACCESS_USERDATA

func display_main():
	get_tree().get_root().add_child(main)
	get_tree().get_root().remove_child(menu)

func _on_new_game_pressed():
	print("Starting game")
	display_main()	
	main.get_node("GameManager").new_game()
	

func _on_settings_button_pressed():
	get_node("/root/Main/OptionsOverlay").visible = true

func _on_exit_pressed():
	print("Exiting")
	get_tree().quit()

func _on_load_button_pressed():
	get_node("LoadTranscript").set_filters(PackedStringArray(["*.txt ; Game transcript"]))
	get_node("LoadTranscript").popup_centered()
	pass # Replace with function body.


func _on_load_transcript_file_selected(path):
	var f = FileAccess.get_file_as_string(path)
	if f == null:
		print(str("Error loading file ", f))
		return
	var t = Logger.GameTranscript.parse(f)
	display_main()
	mgr.load_transcript(t)
