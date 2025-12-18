extends Control

signal back_pressed
signal stamina_refill_requested
signal open_shop_requested
signal episode_play_requested(stamina_cost: int)

# Quest data structure
var chapters: Array[Dictionary] = []
var current_chapter: int = 0

# References to main
var current_stamina: int = 0
var max_stamina: int = 100
var stamina_regen_time: float = 0.0
var stamina_regen_interval: float = 300.0  # 5 minutes in seconds
var current_gems: int = 0
var highest_level_reached: int = 1

var is_initialized: bool = false

@onready var gems_icon = $TopBar/GemsContainer/GemsIcon
@onready var gems_button = $TopBar/GemsContainer/GemsButton
@onready var stamina_label = $TopBar/StaminaContainer/StaminaLabel
@onready var stamina_timer_label = $TopBar/StaminaContainer/TimerLabel
@onready var stamina_refill_button = $TopBar/StaminaContainer/RefillButton

@onready var tab_container = $MainContent/TabContainer
@onready var story_tab = $MainContent/TabContainer/Story
@onready var chapter_buttons_container = $MainContent/TabContainer/Story/ChapterBar/ChapterButtons
@onready var episodes_scroll = $MainContent/TabContainer/Story/EpisodesScroll
@onready var episodes_container = $MainContent/TabContainer/Story/EpisodesScroll/EpisodesVBox

@onready var back_button = $BackButton

func _ready():
	# Load icons
	gems_icon.texture = SpriteManager.get_icon_texture("gems")
	
	# Connect buttons
	gems_button.pressed.connect(_on_gems_button_pressed)
	stamina_refill_button.pressed.connect(_on_stamina_refill_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Setup sidebar tab buttons
	var story_button = $MainContent/Sidebar/SidebarContent/StoryButton
	var boosts_button = $MainContent/Sidebar/SidebarContent/BoostsButton
	var events_button = $MainContent/Sidebar/SidebarContent/EventsButton
	
	story_button.pressed.connect(_on_tab_pressed.bind("Story"))
	boosts_button.pressed.connect(_on_tab_pressed.bind("Boosts"))
	events_button.pressed.connect(_on_tab_pressed.bind("Events"))
	
	# Initialize quest data ONLY if not already initialized
	if not is_initialized:
		initialize_chapters()
		is_initialized = true
	
	# Setup chapter buttons
	setup_chapter_buttons()
	
	# Start with Story tab selected
	_on_tab_pressed("Story")

func initialize_chapters():
	# Define all chapters and episodes
	chapters = [
		{
			"name": "Chapter 1",
			"episodes": [
				{
					"name": "ep. 1",
					"level_req": 1,
					"stamina_cost": 9,
					"stars": 0
				},
				{
					"name": "ep. 2",
					"level_req": 20,
					"stamina_cost": 12,
					"stars": 0
				}
			]
		},
		{
			"name": "Chapter 2",
			"episodes": [
				{
					"name": "ep. 1",
					"level_req": 50,
					"stamina_cost": 15,
					"stars": 0
				},
				{
					"name": "ep. 2",
					"level_req": 75,
					"stamina_cost": 18,
					"stars": 0
				}
			]
		},
		{
			"name": "Chapter 3",
			"episodes": [
				{
					"name": "ep. 1",
					"level_req": 100,
					"stamina_cost": 20,
					"stars": 0
				}
			]
		},
		{
			"name": "Chapter 4",
			"episodes": [
				{
					"name": "ep. 1",
					"level_req": 150,
					"stamina_cost": 25,
					"stars": 0
				}
			]
		}
	]

func setup_chapter_buttons():
	# Clear existing buttons
	for child in chapter_buttons_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Create chapter buttons
	for i in range(chapters.size()):
		var button = Button.new()
		button.text = chapters[i].name
		button.custom_minimum_size = Vector2(120, 50)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_chapter_button_pressed.bind(i))
		chapter_buttons_container.add_child(button)
	
	# Select first chapter
	switch_chapter(0)

func _on_chapter_button_pressed(chapter_index: int):
	switch_chapter(chapter_index)

func switch_chapter(chapter_index: int):
	if chapter_index < 0 or chapter_index >= chapters.size():
		return
	
	current_chapter = chapter_index
	
	# Update button states
	var buttons = chapter_buttons_container.get_children()
	for i in range(buttons.size()):
		if i == chapter_index:
			buttons[i].modulate = Color(0.7, 0.9, 1.0)
			buttons[i].disabled = true
		else:
			buttons[i].modulate = Color.WHITE
			buttons[i].disabled = false
	
	# Refresh episodes display
	refresh_episodes()

func refresh_episodes():
	# Clear existing episode buttons
	for child in episodes_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var chapter_data = chapters[current_chapter]
	
	for i in range(chapter_data.episodes.size()):
		var episode = chapter_data.episodes[i]
		var episode_panel = create_episode_panel(episode, current_chapter, i)
		episodes_container.add_child(episode_panel)

func create_episode_panel(episode: Dictionary, chapter_idx: int, episode_idx: int) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 100)
	
	var hbox = HBoxContainer.new()
	hbox.anchor_left = 0.0
	hbox.anchor_right = 1.0
	hbox.anchor_top = 0.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left = 10
	hbox.offset_top = 10
	hbox.offset_right = -10
	hbox.offset_bottom = -10
	panel.add_child(hbox)
	
	# Left side - Status and info
	var left_vbox = VBoxContainer.new()
	hbox.add_child(left_vbox)
	
	# Check if unlocked
	var is_unlocked = highest_level_reached >= episode.level_req
	
	# Status indicator
	var status_label = Label.new()
	if is_unlocked:
		status_label.text = "Unlocked"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "Locked"
		status_label.add_theme_color_override("font_color", Color.RED)
	status_label.add_theme_font_size_override("font_size", 14)
	left_vbox.add_child(status_label)
	
	# Episode name
	var name_label = Label.new()
	name_label.text = episode.name
	name_label.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(name_label)
	
	# Requirements
	var req_label = Label.new()
	req_label.text = "Level " + str(episode.level_req) + " req."
	req_label.add_theme_font_size_override("font_size", 12)
	req_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	left_vbox.add_child(req_label)
	
	# Stamina cost
	var stamina_label = Label.new()
	stamina_label.text = str(episode.stamina_cost) + " Stamina"
	stamina_label.add_theme_font_size_override("font_size", 12)
	stamina_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	left_vbox.add_child(stamina_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Right side - Play button
	var play_button = Button.new()
	play_button.text = "Play"
	play_button.custom_minimum_size = Vector2(100, 60)
	play_button.add_theme_font_size_override("font_size", 16)
	
	# Disable if locked or not enough stamina
	if not is_unlocked:
		play_button.disabled = true
		play_button.text = "Locked"
	elif current_stamina < episode.stamina_cost:
		play_button.disabled = true
		play_button.text = "Not Enough\nStamina"
		play_button.add_theme_font_size_override("font_size", 12)
	else:
		play_button.pressed.connect(_on_episode_play_pressed.bind(chapter_idx, episode_idx))
	
	hbox.add_child(play_button)
	
	return panel

func _on_episode_play_pressed(chapter_idx: int, episode_idx: int):
	var episode = chapters[chapter_idx].episodes[episode_idx]
	
	# Check stamina
	if current_stamina < episode.stamina_cost:
		show_message("Not enough stamina!")
		return
	
	# Emit signal to Main to consume stamina
	episode_play_requested.emit(episode.stamina_cost)
	
	# Show message
	show_message("Episode started!\n\nConsumed " + str(episode.stamina_cost) + " stamina.\n\n(Story gameplay will be implemented in future updates)")

func update_display():
	# Update gems
	gems_button.text = "Gems: " + str(current_gems) + " (+)"
	
	# Update stamina
	stamina_label.text = "Stamina " + str(current_stamina) + "/" + str(max_stamina)
	
	# Update timer
	if current_stamina < max_stamina:
		var time_remaining = stamina_regen_interval - stamina_regen_time
		var minutes = int(time_remaining / 60)
		var seconds = int(time_remaining) % 60
		stamina_timer_label.text = "(" + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2) + " Left)"
		stamina_timer_label.visible = true
	else:
		stamina_timer_label.text = "(Full)"
		stamina_timer_label.visible = true

func setup(stamina: int, max_stam: int, stam_timer: float, stam_interval: float, gems: int, highest_level: int):
	current_stamina = stamina
	max_stamina = max_stam
	stamina_regen_time = stam_timer
	stamina_regen_interval = stam_interval
	current_gems = gems
	highest_level_reached = highest_level
	
	update_display()
	refresh_episodes()

func _on_tab_pressed(tab_name: String):
	# Hide all tabs
	$MainContent/TabContainer/Story.visible = false
	$MainContent/TabContainer/Boosts.visible = false
	$MainContent/TabContainer/Events.visible = false
	
	# Update button states
	var story_button = $MainContent/Sidebar/SidebarContent/StoryButton
	var boosts_button = $MainContent/Sidebar/SidebarContent/BoostsButton
	var events_button = $MainContent/Sidebar/SidebarContent/EventsButton
	
	story_button.modulate = Color.WHITE
	boosts_button.modulate = Color.WHITE
	events_button.modulate = Color.WHITE
	story_button.disabled = false
	boosts_button.disabled = false
	events_button.disabled = false
	
	# Show selected tab
	match tab_name:
		"Story":
			$MainContent/TabContainer/Story.visible = true
			story_button.modulate = Color(0.7, 0.9, 1.0)
			story_button.disabled = true
		"Boosts":
			$MainContent/TabContainer/Boosts.visible = true
			boosts_button.modulate = Color(0.7, 0.9, 1.0)
			boosts_button.disabled = true
		"Events":
			$MainContent/TabContainer/Events.visible = true
			events_button.modulate = Color(0.7, 0.9, 1.0)
			events_button.disabled = true

func _on_gems_button_pressed():
	# Signal to Main to open shop, then close quest UI
	open_shop_requested.emit()

func _on_stamina_refill_pressed():
	stamina_refill_requested.emit()

func _on_back_pressed():
	back_pressed.emit()

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.title = "Quest"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func get_save_data() -> Dictionary:
	return {
		"chapters": chapters
	}

func load_save_data(data: Dictionary):
	if data.has("chapters"):
		chapters = data.chapters
		is_initialized = true  # Mark as initialized after loading
		refresh_episodes()
