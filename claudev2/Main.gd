# Gacha Functions
extends Control


# Preload the Character class
const Character = preload("res://Character.gd")

# Game currencies
var gold: int = 0
var gems: int = 0
var pull_currency: int = 0
var money: int = 0

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

# UI Scenes
var shop_scene = preload("res://ShopUI.tscn")
var gacha_scene = preload("res://GachaUI.tscn")
var characters_scene = preload("res://CharactersUI.tscn")

# UI Instance references
var shop_ui: Control = null
var gacha_ui: Control = null
var characters_ui: Control = null

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

# Character system
var unlocked_characters: Array[Character] = []
var player_character: Character
var gacha_system: GachaSystem

func _ready():
	gacha_system = GachaSystem.new()
	initialize_player_character()
	spawn_enemy()
	update_ui()
	
	# Connect UI buttons
	shop_button.pressed.connect(_on_shop_button_pressed)
	gacha_button.pressed.connect(_on_gacha_button_pressed)
	characters_button.pressed.connect(_on_characters_button_pressed)
	
	# Hide boss timer initially
	boss_timer_label.visible = false

func initialize_player_character():
	player_character = Character.new()
	player_character.name = "Player"
	player_character.rarity = Character.Rarity.COMMON
	player_character.character_type = Character.Type.CHARACTER
	player_character.base_damage = 10
	player_character.level = 1
	player_character.is_unlocked = true
	unlocked_characters.append(player_character)

func _process(delta):
	handle_money_generation(delta)
	handle_boss_timer(delta)

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

func update_ui():
	level_label.text = "Level: " + str(current_level)
	gold_label.text = "Gold: " + str(gold)
	gems_label.text = "Gems: " + str(gems)
	money_label.text = "Money: " + str(money)
	pull_currency_label.text = "Pulls: " + str(pull_currency)
	
	# Update player damage based on character level
	player_damage = player_character.get_total_damage()
	
	# Update UI button states if UIs are open
	if shop_ui != null and shop_ui.visible:
		shop_ui.update_button_states(money, gems)
	if gacha_ui != null and gacha_ui.visible:
		gacha_ui.update_button_states(pull_currency)

# UI Button handlers
func _on_shop_button_pressed():
	show_shop_ui()

func _on_gacha_button_pressed():
	show_gacha_ui()

func _on_characters_button_pressed():
	show_characters_ui()

# UI Management
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

func hide_all_uis():
	if shop_ui != null:
		shop_ui.visible = false
	if gacha_ui != null:
		gacha_ui.visible = false
	if characters_ui != null:
		characters_ui.visible = false

# Shop Functions
func _on_buy_gems_pressed():
	var cost = 10  # 10 money for 1 gem
	if money >= cost:
		money -= cost
		gems += 1
		update_ui()
		print("Bought 1 gem for ", cost, " money")

func _on_buy_pulls_pressed():
	var cost = 5  # 5 gems for 1 pull currency
	if gems >= cost:
		gems -= cost
		pull_currency += 1
		update_ui()
		print("Bought 1 pull currency for ", cost, " gems")

# Gacha Functions
func _on_character_pull_pressed():
	if pull_currency >= 1:
		pull_currency -= 1
		var result = gacha_system.perform_character_pull()
		process_character_result(result)
		update_ui()
		show_pull_result([result])

func _on_character_pull_10_pressed():
	if pull_currency >= 10:
		pull_currency -= 10
		var results = gacha_system.perform_character_multi_pull(10)
		for result in results:
			process_character_result(result)
		update_ui()
		show_pull_result(results)

func _on_weapon_pull_pressed():
	if pull_currency >= 1:
		pull_currency -= 1
		var result = gacha_system.perform_weapon_pull()
		process_weapon_result(result)
		update_ui()
		show_pull_result([result])

func _on_weapon_pull_10_pressed():
	if pull_currency >= 10:
		pull_currency -= 10
		var results = gacha_system.perform_weapon_multi_pull(10)
		for result in results:
			process_weapon_result(result)
		update_ui()
		show_pull_result(results)

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
	# For now, just add all weapons to the pool (we'll implement weapon equipping later)
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
		var type_text = "★" if result.character_type == Character.Type.CHARACTER else "⚔"
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

# Character Functions
func _on_character_selected(character: Character):
	show_character_popup(character)

func show_character_popup(character: Character):
	# Create popup window
	var popup = AcceptDialog.new()
	popup.title = character.name + " Details"
	popup.size = Vector2(450, 350)
	
	# Create content container
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	# Character header with type and rarity
	var header_container = HBoxContainer.new()
	vbox.add_child(header_container)
	
	var type_indicator = Label.new()
	type_indicator.text = "★" if character.character_type == Character.Type.CHARACTER else "⚔"
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
		info_label.text += "Total Damage: " + str(character.get_total_damage()) + "\n"
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
	
	# Weapon slot (placeholder for now)
	if character.character_type == Character.Type.CHARACTER:
		var weapon_label = Label.new()
		if character.equipped_weapon != null:
			weapon_label.text = "Equipped Weapon: " + character.equipped_weapon.name
		else:
			weapon_label.text = "Equipped Weapon: None"
		vbox.add_child(weapon_label)
	
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
		popup.queue_free()
		print("Upgraded ", character.name, " to level ", character.level)

# Input handling for attacking enemies
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if current_enemy != null and event.button_index == MOUSE_BUTTON_LEFT:
			current_enemy.take_damage(player_damage)
