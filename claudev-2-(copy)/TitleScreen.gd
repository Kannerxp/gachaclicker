extends Control

const SAVE_FILE_PATH = "user://savegame.save"

@onready var title_label = $TitleLabel
@onready var prompt_label = $PromptLabel
@onready var background = $Background
# For future artwork: @onready var artwork = $ArtworkTexture

var has_save: bool = false
var auto_start_timer: float = 0.0
var auto_start_delay: float = 2.0
var is_transitioning: bool = false

func _ready():
	# Check if save file exists
	has_save = FileAccess.file_exists(SAVE_FILE_PATH)
	
	if has_save:
		prompt_label.text = "Loading..."
	else:
		prompt_label.text = "Click anywhere to start"

func _process(delta):
	if has_save and not is_transitioning:
		auto_start_timer += delta
		if auto_start_timer >= auto_start_delay:
			proceed_to_game()

func _input(event):
	if is_transitioning:
		return
	
	# Allow click to proceed
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			proceed_to_game()
	
	# Also allow any key press to proceed
	if event is InputEventKey and event.pressed:
		proceed_to_game()

func proceed_to_game():
	if is_transitioning:
		return  # Already transitioning, prevent multiple calls
	
	is_transitioning = true
	get_tree().change_scene_to_file("res://Main.tscn")
