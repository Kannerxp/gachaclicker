extends Control

const Character = preload("res://Character.gd")

signal character_selected_for_team(character: Character)
signal formation_changed(character: Character, new_formation: Character.Formation)
signal back_pressed

@onready var team_container = $TeamPanel/TeamScrollContainer/TeamVBox
@onready var available_container = $AvailablePanel/AvailableScrollContainer/AvailableVBox
@onready var synergy_label = $SynergyPanel/SynergyLabel
@onready var back_button = $BackButton

var current_team: Array[Character] = []
var available_characters: Array[Character] = []
const MAX_TEAM_SIZE = 5

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	back_pressed.emit()

func refresh_team(team: Array[Character], all_characters: Array[Character]):
	current_team = team
	available_characters = []
	
	# Get available characters (not in team, and are characters not weapons)
	for character in all_characters:
		if character.character_type == Character.Type.CHARACTER and not character.is_in_team and not character.is_player_character:
			available_characters.append(character)
	
	update_team_display()
	update_available_display()
	update_synergy_display()

func update_team_display():
	# Clear existing
	for child in team_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add team header
	var header = Label.new()
	header.text = "Active Team (" + str(current_team.size()) + "/" + str(MAX_TEAM_SIZE) + ")"
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_container.add_child(header)
	
	# Add team members
	for character in current_team:
		var member_container = create_team_member_display(character)
		team_container.add_child(member_container)

func create_team_member_display(character: Character) -> Control:
	var vbox = VBoxContainer.new()
	
	# Character info button
	var info_button = Button.new()
	var formation_text = " [FRONT]" if character.formation_position == Character.Formation.FRONT else " [BACK]"
	info_button.text = character.get_element_icon() + " " + character.name + formation_text
	info_button.modulate = character.get_rarity_color()
	info_button.custom_minimum_size = Vector2(280, 50)
	vbox.add_child(info_button)
	
	# Action buttons container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	# Remove from team button (only if not player)
	if not character.is_player_character:
		var remove_button = Button.new()
		remove_button.text = "Remove"
		remove_button.custom_minimum_size = Vector2(90, 30)
		remove_button.pressed.connect(_on_remove_from_team.bind(character))
		button_container.add_child(remove_button)
	else:
		var player_label = Label.new()
		player_label.text = "[PLAYER]"
		player_label.add_theme_color_override("font_color", Color.GOLD)
		button_container.add_child(player_label)
	
	# Formation toggle button
	var formation_button = Button.new()
	formation_button.text = "⇄ Formation"
	formation_button.custom_minimum_size = Vector2(90, 30)
	formation_button.pressed.connect(_on_toggle_formation.bind(character))
	button_container.add_child(formation_button)
	
	return vbox

func update_available_display():
	# Clear existing
	for child in available_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add header
	var header = Label.new()
	header.text = "Available Characters"
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	available_container.add_child(header)
	
	if available_characters.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No available characters"
		empty_label.modulate = Color.GRAY
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		available_container.add_child(empty_label)
		return
	
	# Add available characters
	for character in available_characters:
		var button = Button.new()
		button.text = character.get_element_icon() + " " + character.name + " [" + character.get_role_name() + "]"
		button.modulate = character.get_rarity_color()
		button.custom_minimum_size = Vector2(280, 50)
		button.disabled = current_team.size() >= MAX_TEAM_SIZE
		button.pressed.connect(_on_add_to_team.bind(character))
		available_container.add_child(button)

func update_synergy_display():
	var synergies = calculate_team_synergies()
	
	var text = "Team Synergies:\n"
	
	if synergies.is_empty():
		text += "No active synergies"
		synergy_label.text = text
		return
	
	for synergy in synergies:
		text += "• " + synergy.name + ": +" + str(int(synergy.bonus * 100)) + "% DMG\n"
	
	synergy_label.text = text

func calculate_team_synergies() -> Array[Dictionary]:
	var synergies: Array[Dictionary] = []
	
	# Count elements
	var element_counts = {}
	for character in current_team:
		var element = character.element
		if element != Character.Element.NEUTRAL:
			element_counts[element] = element_counts.get(element, 0) + 1
	
	# Check for element synergies
	for element in element_counts:
		var count = element_counts[element]
		if count >= 2:
			synergies.append({
				"name": Character.Element.keys()[element] + " Resonance",
				"bonus": 0.1 * count  # 10% per matching element
			})
	
	# Check for opposite element synergies (Fire + Ice, Light + Dark)
	if element_counts.has(Character.Element.FIRE) and element_counts.has(Character.Element.ICE):
		synergies.append({
			"name": "Fire & Ice",
			"bonus": 0.25  # 25% bonus
		})
	
	if element_counts.has(Character.Element.LIGHT) and element_counts.has(Character.Element.DARK):
		synergies.append({
			"name": "Light & Dark",
			"bonus": 0.25  # 25% bonus
		})
	
	# Check for role synergies
	var role_counts = {}
	for character in current_team:
		var role = character.role
		role_counts[role] = role_counts.get(role, 0) + 1
	
	# Balanced team bonus (at least 1 of each role)
	if role_counts.size() == 3:
		synergies.append({
			"name": "Balanced Team",
			"bonus": 0.15  # 15% bonus
		})
	
	return synergies

func _on_add_to_team(character: Character):
	character_selected_for_team.emit(character)

func _on_remove_from_team(character: Character):
	character.is_in_team = false
	refresh_team(current_team.filter(func(c): return c != character), available_characters + current_team)

func _on_toggle_formation(character: Character):
	if character.formation_position == Character.Formation.FRONT:
		character.formation_position = Character.Formation.BACK
	else:
		character.formation_position = Character.Formation.FRONT
	
	formation_changed.emit(character, character.formation_position)
	update_team_display()
	print(character.name, " moved to ", "BACK" if character.formation_position == Character.Formation.BACK else "FRONT")
