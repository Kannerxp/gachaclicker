extends Control

signal character_pull_requested
signal character_pull_10_requested
signal weapon_pull_requested
signal weapon_pull_10_requested
signal back_pressed

# Banner types
enum BannerType {
	NORMAL,
	EVENT,
	LIMITED_TIME
}

# Tab types
enum TabType {
	CHARACTERS,
	WEAPONS
}

var current_banner: BannerType = BannerType.NORMAL
var current_tab: TabType = TabType.CHARACTERS

var current_gems: int = 0
var current_pulls: int = 0

# Banner buttons
var banner_buttons: Dictionary = {}

@onready var gems_icon = $TopBar/CurrencyContainer/GemsIcon
@onready var gems_label = $TopBar/CurrencyContainer/GemsLabel
@onready var pulls_icon = $TopBar/CurrencyContainer/PullsIcon
@onready var pulls_label = $TopBar/CurrencyContainer/PullsLabel

@onready var banner_buttons_container = $MainContent/Sidebar/SidebarContent/BannerButtons
@onready var characters_tab_button = $MainContent/ContentArea/TabButtons/CharactersButton
@onready var weapons_tab_button = $MainContent/ContentArea/TabButtons/WeaponsButton
@onready var background_area = $MainContent/ContentArea/BackgroundArea
@onready var draw_1_button = $MainContent/ContentArea/DrawButtons/Draw1Button
@onready var draw_10_button = $MainContent/ContentArea/DrawButtons/Draw10Button
@onready var pity_label = $MainContent/ContentArea/PityInfo/PityLabel
@onready var back_button = $BackButton

func _ready():
	# Load currency icons
	gems_icon.texture = SpriteManager.get_icon_texture("gems")
	pulls_icon.texture = SpriteManager.get_icon_texture("pulls")
	
	# Setup banner buttons
	setup_banner_buttons()
	
	# Setup tab buttons
	characters_tab_button.pressed.connect(_on_characters_tab_pressed)
	weapons_tab_button.pressed.connect(_on_weapons_tab_pressed)
	
	# Setup draw buttons
	draw_1_button.pressed.connect(_on_draw_1_pressed)
	draw_10_button.pressed.connect(_on_draw_10_pressed)
	
	# Back button
	back_button.pressed.connect(_on_back_pressed)
	
	# Initialize with normal banner and characters tab
	switch_banner(BannerType.NORMAL)
	switch_tab(TabType.CHARACTERS)

func setup_banner_buttons():
	var banners = [
		{"name": "Normal Banner", "banner": BannerType.NORMAL},
		{"name": "Event Banner", "banner": BannerType.EVENT},
		{"name": "Limited Time Banner", "banner": BannerType.LIMITED_TIME}
	]
	
	for banner_data in banners:
		var button = Button.new()
		button.text = banner_data.name
		button.custom_minimum_size = Vector2(180, 50)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_banner_button_pressed.bind(banner_data.banner))
		
		banner_buttons_container.add_child(button)
		banner_buttons[banner_data.banner] = button

func _on_banner_button_pressed(banner: BannerType):
	# Check if banner is available
	if banner == BannerType.EVENT or banner == BannerType.LIMITED_TIME:
		show_message("This banner is not currently available!\n\nComing soon in future updates.")
		return
	
	switch_banner(banner)

func switch_banner(banner: BannerType):
	current_banner = banner
	
	# Update button states
	for banner_type in banner_buttons:
		var button = banner_buttons[banner_type]
		if banner_type == banner:
			button.modulate = Color(0.7, 0.9, 1.0)  # Highlighted
			button.disabled = true
		else:
			button.modulate = Color.WHITE
			button.disabled = false
	
	# Update background placeholder
	update_background()
	
	# Update pity display
	update_pity_display()

func _on_characters_tab_pressed():
	switch_tab(TabType.CHARACTERS)

func _on_weapons_tab_pressed():
	switch_tab(TabType.WEAPONS)

func switch_tab(tab: TabType):
	current_tab = tab
	
	# Update tab button states
	if tab == TabType.CHARACTERS:
		characters_tab_button.modulate = Color(0.7, 0.9, 1.0)
		characters_tab_button.disabled = true
		weapons_tab_button.modulate = Color.WHITE
		weapons_tab_button.disabled = false
	else:
		weapons_tab_button.modulate = Color(0.7, 0.9, 1.0)
		weapons_tab_button.disabled = true
		characters_tab_button.modulate = Color.WHITE
		characters_tab_button.disabled = false
	
	# Update background
	update_background()
	
	# Update pity display
	update_pity_display()

func update_background():
	# Clear existing background content
	for child in background_area.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Create placeholder text
	var placeholder = Label.new()
	placeholder.text = "Custom Background Place Holder"
	placeholder.add_theme_font_size_override("font_size", 36)
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Center it
	placeholder.anchor_left = 0.0
	placeholder.anchor_top = 0.0
	placeholder.anchor_right = 1.0
	placeholder.anchor_bottom = 1.0
	
	background_area.add_child(placeholder)
	
	# Add banner info
	var info = Label.new()
	var banner_name = "Normal Banner"
	var tab_name = "Characters" if current_tab == TabType.CHARACTERS else "Weapons"
	
	info.text = banner_name + " - " + tab_name
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.position = Vector2(0, 50)
	
	info.anchor_left = 0.0
	info.anchor_top = 0.0
	info.anchor_right = 1.0
	info.offset_bottom = 30
	
	background_area.add_child(info)

func _on_draw_1_pressed():
	if current_tab == TabType.CHARACTERS:
		character_pull_requested.emit()
	else:
		weapon_pull_requested.emit()

func _on_draw_10_pressed():
	if current_tab == TabType.CHARACTERS:
		character_pull_10_requested.emit()
	else:
		weapon_pull_10_requested.emit()

func update_currency_display(gems: int, pulls: int):
	current_gems = gems
	current_pulls = pulls
	
	gems_label.text = "Gems: " + str(gems)
	pulls_label.text = "Pulls: " + str(pulls)

func update_button_states(pull_currency: int):
	# Update draw button states based on available pulls
	draw_1_button.disabled = pull_currency < 1
	draw_10_button.disabled = pull_currency < 10
	
	# Update button text to show cost
	draw_1_button.text = "Draw 1\n(1 Pull)"
	draw_10_button.text = "Draw 10\n(10 Pulls)"
	
	# Color buttons based on availability
	if draw_1_button.disabled:
		draw_1_button.modulate = Color(0.5, 0.5, 0.5)
	else:
		draw_1_button.modulate = Color.WHITE
	
	if draw_10_button.disabled:
		draw_10_button.modulate = Color(0.5, 0.5, 0.5)
	else:
		draw_10_button.modulate = Color.WHITE

func update_pity_display(character_pity: int = 0, character_limit: int = 90, weapon_pity: int = 0, weapon_limit: int = 80):
	if current_tab == TabType.CHARACTERS:
		pity_label.text = "Pity: " + str(character_pity) + "/" + str(character_limit)
		
		# Color based on pity progress
		var progress = float(character_pity) / float(character_limit)
		pity_label.modulate = Color.YELLOW.lerp(Color.RED, progress)
	else:
		pity_label.text = "Pity: " + str(weapon_pity) + "/" + str(weapon_limit)
		
		# Color based on pity progress
		var progress = float(weapon_pity) / float(weapon_limit)
		pity_label.modulate = Color.YELLOW.lerp(Color.RED, progress)

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.title = "Gacha"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _on_back_pressed():
	back_pressed.emit()

# Function to show rates (could be called from an info button)
func show_rates_info():
	var rates_text = """
GACHA RATES

Characters:
• Common: 60%
• Rare: 30%
• Legendary: 9.5%
• Mythic: 0.5%

Weapons:
• Common: 70%
• Rare: 25%
• Legendary: 4.5%
• Mythic: 0.5%

Pity System:
• Character: Guaranteed Legendary at 90 pulls
• Weapon: Guaranteed Legendary at 80 pulls
"""
	
	show_message(rates_text)
