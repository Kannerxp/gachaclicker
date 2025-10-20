extends Control

signal character_pull_requested
signal character_pull_10_requested
signal weapon_pull_requested
signal weapon_pull_10_requested
signal back_pressed

@onready var character_pull_button = $TabContainer/CharacterTab/ButtonContainer/PullButton
@onready var character_pull_10_button = $TabContainer/CharacterTab/ButtonContainer/Pull10Button
@onready var character_pity_label = $TabContainer/CharacterTab/PityLabel

@onready var weapon_pull_button = $TabContainer/WeaponTab/ButtonContainer/PullButton
@onready var weapon_pull_10_button = $TabContainer/WeaponTab/ButtonContainer/Pull10Button
@onready var weapon_pity_label = $TabContainer/WeaponTab/PityLabel

@onready var back_button = $BackButton

func _ready():
	character_pull_button.pressed.connect(_on_character_pull_pressed)
	character_pull_10_button.pressed.connect(_on_character_pull_10_pressed)
	weapon_pull_button.pressed.connect(_on_weapon_pull_pressed)
	weapon_pull_10_button.pressed.connect(_on_weapon_pull_10_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_character_pull_pressed():
	character_pull_requested.emit()

func _on_character_pull_10_pressed():
	character_pull_10_requested.emit()

func _on_weapon_pull_pressed():
	weapon_pull_requested.emit()

func _on_weapon_pull_10_pressed():
	weapon_pull_10_requested.emit()

func _on_back_pressed():
	back_pressed.emit()

func update_button_states(pull_currency: int):
	character_pull_button.disabled = pull_currency < 1
	character_pull_10_button.disabled = pull_currency < 10
	weapon_pull_button.disabled = pull_currency < 1
	weapon_pull_10_button.disabled = pull_currency < 10

func update_pity_display(character_pity: int, character_limit: int, weapon_pity: int, weapon_limit: int):
	character_pity_label.text = "Pity: " + str(character_pity) + "/" + str(character_limit)
	weapon_pity_label.text = "Pity: " + str(weapon_pity) + "/" + str(weapon_limit)
	
	# Change color based on pity progress
	var char_progress = float(character_pity) / float(character_limit)
	var weapon_progress = float(weapon_pity) / float(weapon_limit)
	
	character_pity_label.modulate = Color.YELLOW.lerp(Color.RED, char_progress)
	weapon_pity_label.modulate = Color.YELLOW.lerp(Color.RED, weapon_progress)
