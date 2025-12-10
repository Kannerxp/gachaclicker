extends Control
class_name CharacterDisplay

var character: Character = null

@onready var sprite = $Sprite
@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel

func setup(char: Character):
	character = char
	update_display()

func update_display():
	if character == null:
		return
	
	# Set color based on rarity
	sprite.color = character.get_rarity_color()
	
	# Update labels
	name_label.text = character.name
	level_label.text = "Lv." + str(character.level)
	
	# Make name label same color as rarity
	name_label.modulate = character.get_rarity_color()

func refresh():
	update_display()
