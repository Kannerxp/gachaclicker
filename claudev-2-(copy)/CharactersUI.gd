extends Control

# Preload the Character class
const Character = preload("res://Character.gd")

signal character_selected(character: Character)
signal back_pressed

@onready var tab_container = $TabContainer
@onready var character_container = $TabContainer/CharactersTab/ScrollContainer/CharacterContainer
@onready var weapon_container = $TabContainer/WeaponsTab/ScrollContainer/WeaponContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	back_pressed.emit()

func refresh_characters(characters: Array[Character]):
	# Clear existing buttons
	for child in character_container.get_children():
		child.queue_free()
	for child in weapon_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame  # Wait for cleanup
	
	# Separate characters and weapons
	var chars: Array[Character] = []
	var weapons: Array[Character] = []
	
	for character in characters:
		if character.character_type == Character.Type.CHARACTER:
			chars.append(character)
		else:
			weapons.append(character)
	
	# Add character buttons
	for character in chars:
		var character_button = create_character_button(character)
		character_container.add_child(character_button)
	
	# Add weapon buttons
	for weapon in weapons:
		var weapon_button = create_weapon_button(weapon)
		weapon_container.add_child(weapon_button)

func create_character_button(character: Character) -> Button:
	var button = Button.new()
	
	# Enhanced button text with more info
	var button_text = character.get_element_icon() + " " + character.name + " (Lv." + str(character.level) + ")"
	
	if character.is_in_team:
		button_text = "[IN TEAM] " + button_text
	
	if character.duplicate_count > 0:
		button_text += " +Dup(" + str(character.duplicate_count) + ")"
	
	# Add role indicator
	button_text += " [" + character.get_role_name() + "]"
	
	button.text = button_text
	button.custom_minimum_size = Vector2(350, 60)
	
	# Color based on rarity using the new color system
	button.modulate = character.get_rarity_color()
	
	# Make higher rarity characters more prominent
	match character.rarity:
		Character.Rarity.LEGENDARY:
			button.add_theme_font_size_override("font_size", 16)
		Character.Rarity.MYTHIC:
			button.add_theme_font_size_override("font_size", 18)
		_:
			button.add_theme_font_size_override("font_size", 14)
	
	button.pressed.connect(_on_character_button_pressed.bind(character))
	return button

func create_weapon_button(weapon: Character) -> Button:
	var button = Button.new()
	
	# Weapon button text
	var button_text = "⚔ " + weapon.name + " (Lv." + str(weapon.level) + ")"
	button_text += " [+" + str(weapon.get_weapon_damage()) + " DMG]"
	
	if weapon.duplicate_count > 0:
		button_text += " +Dup(" + str(weapon.duplicate_count) + ")"
	
	button.text = button_text
	button.custom_minimum_size = Vector2(350, 60)
	
	# Color based on rarity
	button.modulate = weapon.get_rarity_color()
	
	# Make higher rarity weapons more prominent
	match weapon.rarity:
		Character.Rarity.LEGENDARY:
			button.add_theme_font_size_override("font_size", 16)
		Character.Rarity.MYTHIC:
			button.add_theme_font_size_override("font_size", 18)
		_:
			button.add_theme_font_size_override("font_size", 14)
	
	button.pressed.connect(_on_character_button_pressed.bind(weapon))
	return button

func _on_character_button_pressed(character: Character):
	character_selected.emit(character)
