extends Control

# Preload the Character class
const Character = preload("res://Character.gd")

signal character_selected(character: Character)
signal back_pressed

@onready var character_container = $ScrollContainer/CharacterContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	back_pressed.emit()

func refresh_characters(characters: Array[Character]):
	# Clear existing character buttons
	for child in character_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame  # Wait for cleanup
	
	# Add character buttons
	for character in characters:
		var character_button = create_character_button(character)
		character_container.add_child(character_button)

func create_character_button(character: Character) -> Button:
	var button = Button.new()
	
	# Enhanced button text with more info
	var button_text = character.name + " (Lv." + str(character.level) + ")"
	if character.duplicate_count > 0:
		button_text += " +Dup(" + str(character.duplicate_count) + ")"
	
	# Add type indicator
	var type_indicator = "★" if character.character_type == Character.Type.CHARACTER else "⚔"
	button_text = type_indicator + " " + button_text
	
	button.text = button_text
	button.custom_minimum_size = Vector2(300, 60)
	
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

func _on_character_button_pressed(character: Character):
	character_selected.emit(character)
