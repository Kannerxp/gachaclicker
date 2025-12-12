extends Control

const Character = preload("res://Character.gd")

signal character_selected_for_team(character: Character)
signal formation_changed(character: Character, new_formation: Character.Formation)
signal back_pressed
signal character_removed_from_team(character: Character)

@onready var team_container = $TeamPanel/TeamScrollContainer/TeamVBox
@onready var available_container = $AvailablePanel/AvailableScrollContainer/AvailableVBox
@onready var synergy_label = $SynergyPanel/SynergyLabel
@onready var synergy_panel = $SynergyPanel
@onready var back_button = $BackButton

var total_dps_label: Label = null
var current_team: Array[Character] = []
var available_characters: Array[Character] = []
var current_total_dps: int = 0
const MAX_TEAM_SIZE = 5

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	
	# Create TotalDPSLabel if it doesn't exist
	if not synergy_panel.has_node("TotalDPSLabel"):
		total_dps_label = Label.new()
		total_dps_label.name = "TotalDPSLabel"
		total_dps_label.text = "Total DPS: 0"
		total_dps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		total_dps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		total_dps_label.add_theme_font_size_override("font_size", 18)
		total_dps_label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
		
		# Set anchors and position
		total_dps_label.anchor_left = 0.0
		total_dps_label.anchor_top = 0.0
		total_dps_label.anchor_right = 1.0
		total_dps_label.anchor_bottom = 0.0
		total_dps_label.offset_left = 10
		total_dps_label.offset_top = 10
		total_dps_label.offset_right = -10
		total_dps_label.offset_bottom = 40
		
		synergy_panel.add_child(total_dps_label)
		
		# Adjust synergy_label position to make room
		synergy_label.offset_top = 50
	else:
		total_dps_label = synergy_panel.get_node("TotalDPSLabel")

func _on_back_pressed():
	back_pressed.emit()

func refresh_team(team: Array[Character], all_characters: Array[Character], total_dps: int = 0):
	current_team = team
	current_total_dps = total_dps
	available_characters = []
	
	# Get available characters (not in team, and are characters not weapons)
	for character in all_characters:
		if character.character_type == Character.Type.CHARACTER and not character.is_in_team and not character.is_player_character:
			available_characters.append(character)
	
	update_team_display()
	update_available_display()
	update_synergy_display()
	update_total_dps_display()

func update_total_dps_display():
	if total_dps_label != null:
		total_dps_label.text = "Total DPS: " + str(current_total_dps)

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
	
	# Add formation guide
	var guide = Label.new()
	guide.text = "FRONT: +15% DMG, +20% Cooldown\nBACK: -10% DMG, -25% Cooldown"
	guide.add_theme_font_size_override("font_size", 10)
	guide.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_container.add_child(guide)
	
	var separator1 = HSeparator.new()
	team_container.add_child(separator1)
	
	# Add team members
	for character in current_team:
		var member_container = create_team_member_display(character)
		team_container.add_child(member_container)

func create_team_member_display(character: Character) -> Control:
	var vbox = VBoxContainer.new()
	
	# Character info with formation
	var info_container = HBoxContainer.new()
	vbox.add_child(info_container)
	
	# Element icon
	var element_label = Label.new()
	element_label.text = character.get_element_icon()
	element_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(element_label)
	
	# Character name + formation
	var name_label = Label.new()
	var formation_icon = "▲" if character.formation_position == Character.Formation.FRONT else "▼"
	name_label.text = character.name + " " + formation_icon
	name_label.modulate = character.get_rarity_color()
	name_label.add_theme_font_size_override("font_size", 14)
	info_container.add_child(name_label)
	
	# Stats display with formation modifiers
	var stats_label = Label.new()
	var base_dmg = character.get_total_damage()
	var modified_dmg = int(base_dmg * character.get_formation_multiplier())
	var base_cd = character.ability_cooldown_max
	var modified_cd = base_cd * character.get_formation_cooldown_multiplier()
	
	stats_label.text = "DMG: " + str(base_dmg) + " → " + str(modified_dmg)
	stats_label.text += " | CD: " + str(base_cd) + "s → " + str(snapped(modified_cd, 0.1)) + "s"
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(stats_label)
	
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
	var current_formation_text = "FRONT" if character.formation_position == Character.Formation.FRONT else "BACK"
	var next_formation_text = "BACK" if character.formation_position == Character.Formation.FRONT else "FRONT"
	formation_button.text = "→ " + next_formation_text
	formation_button.custom_minimum_size = Vector2(90, 30)
	
	# Color code the button
	if character.formation_position == Character.Formation.FRONT:
		formation_button.modulate = Color(0.8, 1.0, 0.8)  # Green tint for switching to back
	else:
		formation_button.modulate = Color(1.0, 0.8, 0.8)  # Red tint for switching to front
	
	formation_button.pressed.connect(_on_toggle_formation.bind(character))
	button_container.add_child(formation_button)
	
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
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
	character_removed_from_team.emit(character)

func _on_toggle_formation(character: Character):
	if character.formation_position == Character.Formation.FRONT:
		character.formation_position = Character.Formation.BACK
		print(character.name, " moved to BACK (-10% DMG, -25% Cooldown)")
	else:
		character.formation_position = Character.Formation.FRONT
		print(character.name, " moved to FRONT (+15% DMG, +20% Cooldown)")
	
	formation_changed.emit(character, character.formation_position)
	update_team_display()
