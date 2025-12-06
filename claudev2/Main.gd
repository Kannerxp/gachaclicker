# Gacha Functions
extends Control

# Preload the Character class
const Character = preload("res://Character.gd")

# Save file path
const SAVE_FILE_PATH = "user://savegame.save"

# Game currencies
var gold: int = 0
var gems: int = 20
var pull_currency: int = 20
var money: int = 20

# Game progression
var current_level: int = 1
var player_damage: int = 10

# Enemy system
var current_enemy: Enemy = null
var enemy_scene = preload("res://Enemy.tscn")

# Boss system
var boss_timer: float = 0.0
var boss_time_limit: float = 15.0
var is_boss_level: bool = false

# Money generation timer
var money_timer: float = 0.0
var money_generation_interval: float = 60.0  # 1 minute

# Auto-attack system
var auto_attack_timer: float = 0.0
var auto_attack_interval: float = 1.0  # Attack every 1 second

# UI Scenes
var shop_scene = preload("res://ShopUI.tscn")
var gacha_scene = preload("res://GachaUI.tscn")
var characters_scene = preload("res://CharactersUI.tscn")
var team_scene = preload("res://TeamUI.tscn")

# UI Instance references
var shop_ui: Control = null
var gacha_ui: Control = null
var characters_ui: Control = null
var team_ui: Control = null

# UI References
@onready var level_label = $UI/TopPanel/LevelLabel
@onready var gold_label = $UI/TopPanel/GoldLabel
@onready var gems_label = $UI/TopPanel/GemsLabel
@onready var money_label = $UI/TopPanel/MoneyLabel
@onready var pull_currency_label = $UI/TopPanel/PullCurrencyLabel
@onready var enemy_container = $EnemyContainer
@onready var boss_timer_label = $UI/BossTimerLabel

# UI Buttons
@onready var shop_button = $UI/BottomPanel/ShopButton
@onready var gacha_button = $UI/BottomPanel/GachaButton
@onready var characters_button = $UI/BottomPanel/CharactersButton
@onready var team_button = $UI/BottomPanel/TeamButton

# Character system
var unlocked_characters: Array[Character] = []
var player_character: Character
var gacha_system: GachaSystem

# Team system
var active_team: Array[Character] = []
const MAX_TEAM_SIZE = 5

func _ready():
	gacha_system = GachaSystem.new()
	
	# Try to load saved game first
	if load_game():
		print("Game loaded successfully!")
	else:
		# If no save exists, initialize new game
		initialize_player_character()
	
	spawn_enemy()
	update_ui()
	
	# Connect UI buttons
	shop_button.pressed.connect(_on_shop_button_pressed)
	gacha_button.pressed.connect(_on_gacha_button_pressed)
	characters_button.pressed.connect(_on_characters_button_pressed)
	team_button.pressed.connect(_on_team_button_pressed)
	
	# Hide boss timer initially
	boss_timer_label.visible = false
	
	# Auto-save every 30 seconds
	var save_timer = Timer.new()
	save_timer.wait_time = 30.0
	save_timer.autostart = true
	save_timer.timeout.connect(save_game)
	add_child(save_timer)

func initialize_player_character():
	player_character = Character.new()
	player_character.name = "Player"
	player_character.rarity = Character.Rarity.COMMON
	player_character.character_type = Character.Type.CHARACTER
	player_character.base_damage = 10
	player_character.level = 1
	player_character.is_unlocked = true
	player_character.is_player_character = true  # Mark as player character
	player_character.character_id = 0  # Special ID for player
	player_character.role = Character.Role.DPS
	player_character.element = Character.Element.NEUTRAL
	player_character.formation_position = Character.Formation.FRONT
	player_character.is_in_team = true
	unlocked_characters.append(player_character)
	active_team.append(player_character)

func _process(delta):
	handle_money_generation(delta)
	handle_boss_timer(delta)
	handle_auto_attack(delta)

func handle_money_generation(delta):
	money_timer += delta
	if money_timer >= money_generation_interval:
		money_timer = 0.0
		money += 1
		update_ui()
		print("Generated 1 money! Total: ", money)

func handle_boss_timer(delta):
	if is_boss_level and current_enemy != null:
		boss_timer -= delta
		boss_timer_label.text = "Boss Timer: " + str(ceil(boss_timer))
		
		if boss_timer <= 0.0:
			# Boss timer expired, send player back 3 levels
			current_level = max(1, current_level - 3)
			print("Boss timer expired! Sent back to level: ", current_level)
			boss_timer_label.visible = false
			is_boss_level = false
			spawn_enemy()
			update_ui()

func handle_auto_attack(delta):
	if current_enemy == null:
		return
	
	auto_attack_timer += delta
	if auto_attack_timer >= auto_attack_interval:
		auto_attack_timer = 0.0
		
		# Calculate total damage from active team (excluding player for auto-attack)
		var total_auto_damage = calculate_team_damage(false)
		
		# Apply damage to enemy
		if total_auto_damage > 0:
			current_enemy.take_damage(total_auto_damage)

# ========== TEAM SYSTEM ==========

func calculate_team_damage(include_player: bool = true) -> int:
	var total_damage = 0
	
	for character in active_team:
		# Skip player if requested (for auto-attack calculation)
		if not include_player and character.is_player_character:
			continue
		
		# Base damage with role and formation multipliers
		var char_damage = character.get_total_damage()
		char_damage = int(char_damage * character.get_role_multiplier())
		char_damage = int(char_damage * character.get_formation_multiplier())
		
		total_damage += char_damage
	
	# Apply team synergies
	var synergy_multiplier = get_team_synergy_multiplier()
	total_damage = int(total_damage * synergy_multiplier)
	
	return total_damage

func get_team_synergy_multiplier() -> float:
	var multiplier = 1.0
	
	# Count elements
	var element_counts = {}
	for character in active_team:
		var element = character.element
		if element != Character.Element.NEUTRAL:
			element_counts[element] = element_counts.get(element, 0) + 1
	
	# Element resonance bonus (10% per matching element, minimum 2)
	for element in element_counts:
		var count = element_counts[element]
		if count >= 2:
			multiplier += 0.1 * count
	
	# Opposite element synergies
	if element_counts.has(Character.Element.FIRE) and element_counts.has(Character.Element.ICE):
		multiplier += 0.25
	
	if element_counts.has(Character.Element.LIGHT) and element_counts.has(Character.Element.DARK):
		multiplier += 0.25
	
	# Role synergies
	var role_counts = {}
	for character in active_team:
		var role = character.role
		role_counts[role] = role_counts.get(role, 0) + 1
	
	# Balanced team bonus (all 3 roles present)
	if role_counts.size() == 3:
		multiplier += 0.15
	
	return multiplier

func add_to_team(character: Character):
	if active_team.size() >= MAX_TEAM_SIZE:
		print("Team is full!")
		return
	
	if character.is_in_team:
		print(character.name, " is already in the team!")
		return
	
	character.is_in_team = true
	active_team.append(character)
	print("Added ", character.name, " to the team!")
	save_game()

func remove_from_team(character: Character):
	if character.is_player_character:
		print("Cannot remove player character from team!")
		return
	
	character.is_in_team = false
	active_team.erase(character)
	print("Removed ", character.name, " from the team!")
	save_game()

# ========== SPAWN/COMBAT ==========

func spawn_enemy():
	# Remove current enemy if it exists
	if current_enemy != null:
		current_enemy.queue_free()
	
	# Check if this is a boss level (every 10 levels)
	is_boss_level = (current_level % 10 == 0)
	
	# Create new enemy
	current_enemy = enemy_scene.instantiate()
	enemy_container.add_child(current_enemy)
	
	# Configure enemy based on level and boss status
	if is_boss_level:
		current_enemy.setup_as_boss(current_level)
		boss_timer = boss_time_limit
		boss_timer_label.visible = true
		boss_timer_label.text = "Boss Timer: " + str(int(boss_timer))
	else:
		current_enemy.setup_as_normal(current_level)
		boss_timer_label.visible = false
	
	# Connect enemy defeat signal
	current_enemy.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(gold_reward: int):
	gold += gold_reward
	current_level += 1
	
	print("Enemy defeated! Gold: +", gold_reward, " Level: ", current_level)
	
	# Reset boss status
	if is_boss_level:
		is_boss_level = false
		boss_timer_label.visible = false
	
	spawn_enemy()
	update_ui()
	save_game()  # Save on level up

func update_ui():
	level_label.text = "Level: " + str(current_level)
	gold_label.text = "Gold: " + str(gold)
	gems_label.text = "Gems: " + str(gems)
	money_label.text = "Money: " + str(money)
	pull_currency_label.text = "Pulls: " + str(pull_currency)
	
	# Update player damage based on team damage
	player_damage = calculate_team_damage(true)
	
	# Update UI button states if UIs are open
	if shop_ui != null and shop_ui.visible:
		shop_ui.update_button_states(money, gems)
	if gacha_ui != null and gacha_ui.visible:
		gacha_ui.update_button_states(pull_currency)

# ========== SAVE/LOAD SYSTEM ==========

func save_game():
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("Error: Could not open save file for writing!")
		return
	
	var save_data = {
		"gold": gold,
		"gems": gems,
		"pull_currency": pull_currency,
		"money": money,
		"current_level": current_level,
		"characters": serialize_characters(),
		"gacha_pity": gacha_system.get_pity_info(),
		"active_team_ids": serialize_team()
	}
	
	var json_string = JSON.stringify(save_data)
	save_file.store_string(json_string)
	save_file.close()
	print("Game saved!")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found.")
		return false
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		print("Error: Could not open save file for reading!")
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Error: Could not parse save file!")
		return false
	
	var save_data = json.data
	
	# Load currencies and progression
	gold = save_data.get("gold", 0)
	gems = save_data.get("gems", 20)
	pull_currency = save_data.get("pull_currency", 20)
	money = save_data.get("money", 20)
	current_level = save_data.get("current_level", 1)
	
	# Load characters
	deserialize_characters(save_data.get("characters", []))
	
	# Load active team
	deserialize_team(save_data.get("active_team_ids", []))
	
	# Load gacha pity
	var pity_info = save_data.get("gacha_pity", {})
	gacha_system.character_pity_count = pity_info.get("character_pity", 0)
	gacha_system.weapon_pity_count = pity_info.get("weapon_pity", 0)
	
	return true

func serialize_characters() -> Array:
	var serialized = []
	
	for character in unlocked_characters:
		var char_data = {
			"character_id": character.character_id,
			"name": character.name,
			"rarity": character.rarity,
			"character_type": character.character_type,
			"level": character.level,
			"base_damage": character.base_damage,
			"duplicate_count": character.duplicate_count,
			"is_player_character": character.is_player_character,
			"equipped_weapon_id": character.equipped_weapon.character_id if character.equipped_weapon != null else -1,
			"role": character.role,
			"element": character.element,
			"formation_position": character.formation_position,
			"is_in_team": character.is_in_team
		}
		serialized.append(char_data)
	
	return serialized

func deserialize_characters(serialized_data: Array):
	unlocked_characters.clear()
	
	# First pass: Create all characters
	for char_data in serialized_data:
		var character = Character.new()
		character.character_id = char_data.get("character_id", -1)
		character.name = char_data.get("name", "Unknown")
		character.rarity = char_data.get("rarity", Character.Rarity.COMMON)
		character.character_type = char_data.get("character_type", Character.Type.CHARACTER)
		character.level = char_data.get("level", 1)
		character.base_damage = char_data.get("base_damage", 10)
		character.duplicate_count = char_data.get("duplicate_count", 0)
		character.is_unlocked = true
		character.is_player_character = char_data.get("is_player_character", false)
		character.role = char_data.get("role", Character.Role.DPS)
		character.element = char_data.get("element", Character.Element.NEUTRAL)
		character.formation_position = char_data.get("formation_position", Character.Formation.FRONT)
		character.is_in_team = char_data.get("is_in_team", false)
		
		unlocked_characters.append(character)
		
		# Set player character reference
		if character.is_player_character:
			player_character = character
	
	# Second pass: Restore weapon equipment
	for i in range(serialized_data.size()):
		var char_data = serialized_data[i]
		var equipped_weapon_id = char_data.get("equipped_weapon_id", -1)
		
		if equipped_weapon_id != -1:
			var weapon = find_character_by_id(equipped_weapon_id)
			if weapon != null:
				unlocked_characters[i].equipped_weapon = weapon

func serialize_team() -> Array:
	var team_ids = []
	for character in active_team:
		team_ids.append(character.character_id)
	return team_ids

func deserialize_team(team_ids: Array):
	active_team.clear()
	for char_id in team_ids:
		var character = find_character_by_id(char_id)
		if character != null:
			active_team.append(character)

# ========== RESET PROGRESS ==========

func reset_progress():
	# Delete save file
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	
	# Reload the scene
	get_tree().reload_current_scene()
	print("Progress reset!")

# ========== WEAPON EQUIPPING SYSTEM ==========

func get_available_weapons() -> Array[Character]:
	var weapons: Array[Character] = []
	for character in unlocked_characters:
		if character.character_type == Character.Type.WEAPON:
			weapons.append(character)
	return weapons

func equip_weapon(character: Character, weapon: Character):
	if weapon.character_type != Character.Type.WEAPON:
		print("Error: Can only equip weapons!")
		return
	
	# Unequip from previous owner if already equipped
	for other_char in unlocked_characters:
		if other_char.equipped_weapon == weapon:
			other_char.equipped_weapon = null
			print("Unequipped ", weapon.name, " from ", other_char.name)
	
	# Equip to new character
	character.equipped_weapon = weapon
	print("Equipped ", weapon.name, " to ", character.name)
	update_ui()
	save_game()

func unequip_weapon(character: Character):
	if character.equipped_weapon != null:
		print("Unequipped ", character.equipped_weapon.name, " from ", character.name)
		character.equipped_weapon = null
		update_ui()
		save_game()

# ========== UI MANAGEMENT ==========

func _on_shop_button_pressed():
	show_shop_ui()

func _on_gacha_button_pressed():
	show_gacha_ui()

func _on_characters_button_pressed():
	show_characters_ui()

func _on_team_button_pressed():
	show_team_ui()

func show_shop_ui():
	hide_all_uis()
	
	if shop_ui == null:
		shop_ui = shop_scene.instantiate()
		add_child(shop_ui)
		
		# Connect signals
		shop_ui.buy_gems_requested.connect(_on_buy_gems_pressed)
		shop_ui.buy_pulls_requested.connect(_on_buy_pulls_pressed)
		shop_ui.back_pressed.connect(hide_all_uis)
	
	shop_ui.visible = true
	shop_ui.update_button_states(money, gems)

func show_gacha_ui():
	hide_all_uis()
	
	if gacha_ui == null:
		gacha_ui = gacha_scene.instantiate()
		add_child(gacha_ui)
		
		# Connect signals
		gacha_ui.character_pull_requested.connect(_on_character_pull_pressed)
		gacha_ui.character_pull_10_requested.connect(_on_character_pull_10_pressed)
		gacha_ui.weapon_pull_requested.connect(_on_weapon_pull_pressed)
		gacha_ui.weapon_pull_10_requested.connect(_on_weapon_pull_10_pressed)
		gacha_ui.back_pressed.connect(hide_all_uis)
	
	gacha_ui.visible = true
	gacha_ui.update_button_states(pull_currency)
	
	# Update pity display
	var pity_info = gacha_system.get_pity_info()
	gacha_ui.update_pity_display(
		pity_info.character_pity,
		pity_info.character_pity_limit,
		pity_info.weapon_pity,
		pity_info.weapon_pity_limit
	)

func show_characters_ui():
	hide_all_uis()
	
	if characters_ui == null:
		characters_ui = characters_scene.instantiate()
		add_child(characters_ui)
		
		# Connect signals
		characters_ui.character_selected.connect(_on_character_selected)
		characters_ui.back_pressed.connect(hide_all_uis)
	
	characters_ui.visible = true
	characters_ui.refresh_characters(unlocked_characters)

func show_team_ui():
	hide_all_uis()
	
	if team_ui == null:
		team_ui = team_scene.instantiate()
		add_child(team_ui)
		
		# Connect signals
		team_ui.character_selected_for_team.connect(_on_character_selected_for_team)
		team_ui.formation_changed.connect(_on_formation_changed)
		team_ui.back_pressed.connect(hide_all_uis)
	
	team_ui.visible = true
	team_ui.refresh_team(active_team, unlocked_characters)

func hide_all_uis():
	if shop_ui != null:
		shop_ui.visible = false
	if gacha_ui != null:
		gacha_ui.visible = false
	if characters_ui != null:
		characters_ui.visible = false
	if team_ui != null:
		team_ui.visible = false

# ========== SHOP FUNCTIONS ==========

func _on_buy_gems_pressed():
	var cost = 10  # 10 money for 1 gem
	if money >= cost:
		money -= cost
		gems += 1
		update_ui()
		save_game()
		print("Bought 1 gem for ", cost, " money")

func _on_buy_pulls_pressed():
	var cost = 5  # 5 gems for 1 pull currency
	if gems >= cost:
		gems -= cost
		pull_currency += 1
		update_ui()
		save_game()
		print("Bought 1 pull currency for ", cost, " gems")

# ========== GACHA FUNCTIONS ==========

func _on_character_pull_pressed():
	if pull_currency >= 1:
		pull_currency -= 1
		var result = gacha_system.perform_character_pull()
		process_character_result(result)
		update_ui()
		show_pull_result([result])
		save_game()

func _on_character_pull_10_pressed():
	if pull_currency >= 10:
		pull_currency -= 10
		var results = gacha_system.perform_character_multi_pull(10)
		for result in results:
			process_character_result(result)
		update_ui()
		show_pull_result(results)
		save_game()

func _on_weapon_pull_pressed():
	if pull_currency >= 1:
		pull_currency -= 1
		var result = gacha_system.perform_weapon_pull()
		process_weapon_result(result)
		update_ui()
		show_pull_result([result])
		save_game()

func _on_weapon_pull_10_pressed():
	if pull_currency >= 10:
		pull_currency -= 10
		var results = gacha_system.perform_weapon_multi_pull(10)
		for result in results:
			process_weapon_result(result)
		update_ui()
		show_pull_result(results)
		save_game()

func process_character_result(new_character: Character):
	# Check for duplicates
	var existing_character = find_character_by_id(new_character.character_id)
	if existing_character != null:
		# Handle duplicate
		existing_character.add_duplicate()
		print("Duplicate! ", existing_character.name, " now has ", existing_character.duplicate_count, " duplicates")
	else:
		# New character
		unlocked_characters.append(new_character)
		print("New character unlocked: ", new_character.name)

func process_weapon_result(new_weapon: Character):
	# Check for duplicates
	var existing_weapon = find_character_by_id(new_weapon.character_id)
	if existing_weapon != null:
		# Handle duplicate
		existing_weapon.add_duplicate()
		print("Duplicate weapon! ", existing_weapon.name, " now has ", existing_weapon.duplicate_count, " duplicates")
	else:
		# New weapon
		unlocked_characters.append(new_weapon)
		print("New weapon obtained: ", new_weapon.name)

func find_character_by_id(character_id: int) -> Character:
	for character in unlocked_characters:
		if character.character_id == character_id:
			return character
	return null

func show_pull_result(results: Array[Character]):
	# Create a results popup
	var popup = AcceptDialog.new()
	popup.title = "Gacha Results!"
	popup.size = Vector2(500, 400)
	
	# Create scroll container for results
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# Add header
	var header_label = Label.new()
	if results.size() == 1:
		header_label.text = "Single Pull Result:"
	else:
		header_label.text = "10-Pull Results:"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header_label)
	
	# Count rarities for summary
	var rarity_counts = {
		Character.Rarity.COMMON: 0,
		Character.Rarity.RARE: 0,
		Character.Rarity.LEGENDARY: 0,
		Character.Rarity.MYTHIC: 0
	}
	
	# Display each result
	for result in results:
		var result_container = HBoxContainer.new()
		vbox.add_child(result_container)
		
		# Rarity indicator (colored rectangle)
		var color_rect = ColorRect.new()
		color_rect.color = result.get_rarity_color()
		color_rect.custom_minimum_size = Vector2(20, 30)
		result_container.add_child(color_rect)
		
		# Character info
		var info_label = Label.new()
		var rarity_text = Character.Rarity.keys()[result.rarity]
		var type_text = result.get_element_icon() if result.character_type == Character.Type.CHARACTER else "⚔"
		info_label.text = type_text + " " + result.name + " (" + rarity_text + ")"
		info_label.modulate = result.get_rarity_color()
		result_container.add_child(info_label)
		
		# Check if duplicate
		var existing = find_character_by_id(result.character_id)
		if existing != null and existing.duplicate_count > 0:
			var dup_label = Label.new()
			dup_label.text = " +Dup(" + str(existing.duplicate_count) + ")"
			dup_label.modulate = Color.ORANGE
			result_container.add_child(dup_label)
		
		rarity_counts[result.rarity] += 1
	
	# Add summary for multi-pulls
	if results.size() > 1:
		var separator = HSeparator.new()
		vbox.add_child(separator)
		
		var summary_label = Label.new()
		summary_label.text = "Summary:\n"
		if rarity_counts[Character.Rarity.MYTHIC] > 0:
			summary_label.text += "Mythic: " + str(rarity_counts[Character.Rarity.MYTHIC]) + "\n"
		if rarity_counts[Character.Rarity.LEGENDARY] > 0:
			summary_label.text += "Legendary: " + str(rarity_counts[Character.Rarity.LEGENDARY]) + "\n"
		if rarity_counts[Character.Rarity.RARE] > 0:
			summary_label.text += "Rare: " + str(rarity_counts[Character.Rarity.RARE]) + "\n"
		if rarity_counts[Character.Rarity.COMMON] > 0:
			summary_label.text += "Common: " + str(rarity_counts[Character.Rarity.COMMON])
		
		summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(summary_label)
	
	# Show popup
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)

# ========== CHARACTER FUNCTIONS ==========

func _on_character_selected(character: Character):
	show_character_popup(character)

func _on_character_selected_for_team(character: Character):
	add_to_team(character)
	if team_ui != null:
		team_ui.refresh_team(active_team, unlocked_characters)
	update_ui()

func _on_formation_changed(character: Character, new_formation: Character.Formation):
	save_game()
	update_ui()

func show_character_popup(character: Character):
	# Create popup window
	var popup = AcceptDialog.new()
	popup.title = character.name + " Details"
	popup.size = Vector2(450, 500)
	
	# Create content container
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	# Character header with type and rarity
	var header_container = HBoxContainer.new()
	vbox.add_child(header_container)
	
	var type_indicator = Label.new()
	if character.character_type == Character.Type.CHARACTER:
		type_indicator.text = character.get_element_icon()
	else:
		type_indicator.text = "⚔"
	type_indicator.add_theme_font_size_override("font_size", 24)
	type_indicator.modulate = character.get_rarity_color()
	header_container.add_child(type_indicator)
	
	var name_label = Label.new()
	name_label.text = character.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.modulate = character.get_rarity_color()
	header_container.add_child(name_label)
	
	# Character info
	var info_label = Label.new()
	var rarity_text = Character.Rarity.keys()[character.rarity]
	var type_text = "Character" if character.character_type == Character.Type.CHARACTER else "Weapon"
	
	info_label.text = "Type: " + type_text + "\n"
	info_label.text += "Rarity: " + rarity_text + "\n"
	info_label.text += "Level: " + str(character.level) + "\n"
	
	if character.character_type == Character.Type.CHARACTER:
		info_label.text += "Role: " + character.get_role_name() + "\n"
		info_label.text += "Element: " + character.get_element_name() + "\n"
		info_label.text += "Formation: " + ("FRONT" if character.formation_position == Character.Formation.FRONT else "BACK") + "\n"
		info_label.text += "Total Damage: " + str(character.get_total_damage()) + "\n"
		info_label.text += "In Team: " + ("Yes" if character.is_in_team else "No") + "\n"
	else:
		info_label.text += "Weapon Damage: " + str(character.get_weapon_damage()) + "\n"
	
	if character.duplicate_count > 0:
		info_label.text += "Duplicates: " + str(character.duplicate_count) + " (+Damage Bonus)\n"
	
	info_label.text += "Upgrade Cost: " + str(character.get_upgrade_cost()) + " Gold"
	vbox.add_child(info_label)
	
	# Only show upgrade button for characters (not weapons for now)
	if character.character_type == Character.Type.CHARACTER:
		var upgrade_button = Button.new()
		upgrade_button.text = "Upgrade (" + str(character.get_upgrade_cost()) + " Gold)"
		upgrade_button.disabled = gold < character.get_upgrade_cost()
		upgrade_button.pressed.connect(_on_upgrade_character.bind(character, popup))
		vbox.add_child(upgrade_button)
	
	# Weapon management section (only for characters)
	if character.character_type == Character.Type.CHARACTER:
		var separator = HSeparator.new()
		vbox.add_child(separator)
		
		var weapon_title = Label.new()
		weapon_title.text = "Equipped Weapon:"
		weapon_title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(weapon_title)
		
		# Current weapon display
		var current_weapon_label = Label.new()
		if character.equipped_weapon != null:
			current_weapon_label.text = "⚔ " + character.equipped_weapon.name + " (+" + str(character.equipped_weapon.get_weapon_damage()) + " DMG)"
			current_weapon_label.modulate = character.equipped_weapon.get_rarity_color()
		else:
			current_weapon_label.text = "None"
			current_weapon_label.modulate = Color.GRAY
		vbox.add_child(current_weapon_label)
		
		# Unequip button
		if character.equipped_weapon != null:
			var unequip_button = Button.new()
			unequip_button.text = "Unequip Weapon"
			unequip_button.pressed.connect(_on_unequip_weapon.bind(character, popup))
			vbox.add_child(unequip_button)
		
		# Weapon selection dropdown
		var available_weapons = get_available_weapons()
		if available_weapons.size() > 0:
			var weapon_select_label = Label.new()
			weapon_select_label.text = "Select Weapon to Equip:"
			vbox.add_child(weapon_select_label)
			
			var weapon_scroll = ScrollContainer.new()
			weapon_scroll.custom_minimum_size = Vector2(400, 100)
			vbox.add_child(weapon_scroll)
			
			var weapon_vbox = VBoxContainer.new()
			weapon_scroll.add_child(weapon_vbox)
			
			for weapon in available_weapons:
				var weapon_button = Button.new()
				var weapon_dmg = weapon.get_weapon_damage()
				weapon_button.text = "⚔ " + weapon.name + " (+" + str(weapon_dmg) + " DMG)"
				
				# Show if weapon is equipped elsewhere
				var equipped_to = ""
				for other_char in unlocked_characters:
					if other_char.equipped_weapon == weapon:
						equipped_to = " [Equipped to " + other_char.name + "]"
						break
				
				weapon_button.text += equipped_to
				weapon_button.modulate = weapon.get_rarity_color()
				
				# Disable if it's the currently equipped weapon
				weapon_button.disabled = (character.equipped_weapon == weapon)
				
				weapon_button.pressed.connect(_on_equip_weapon.bind(character, weapon, popup))
				weapon_vbox.add_child(weapon_button)
	
	# Add popup to scene
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)

func _on_upgrade_character(character: Character, popup: AcceptDialog):
	var cost = character.get_upgrade_cost()
	if gold >= cost:
		gold -= cost
		character.upgrade_character(cost)
		update_ui()
		save_game()
		popup.queue_free()
		# Reopen the popup with updated info
		show_character_popup(character)
		print("Upgraded ", character.name, " to level ", character.level)

func _on_equip_weapon(character: Character, weapon: Character, popup: AcceptDialog):
	equip_weapon(character, weapon)
	popup.queue_free()
	# Reopen the popup with updated info
	show_character_popup(character)

func _on_unequip_weapon(character: Character, popup: AcceptDialog):
	unequip_weapon(character)
	popup.queue_free()
	# Reopen the popup with updated info
	show_character_popup(character)

# ========== INPUT HANDLING ==========

func _input(event):
	# Player character manual attack
	if event is InputEventMouseButton and event.pressed:
		if current_enemy != null and event.button_index == MOUSE_BUTTON_LEFT:
			# Player damage is calculated as total team damage
			current_enemy.take_damage(player_damage)
	
	# Cheat code to reset progress (Press R key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if Input.is_key_pressed(KEY_CTRL):
			reset_progress()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save game when closing
		save_game()
		get_tree().quit()
