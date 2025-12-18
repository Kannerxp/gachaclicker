class_name PrestigeSystem
extends RefCounted

# Prestige currency
var prestige_points: int = 0

# Purchased upgrades (by ID)
var purchased_upgrades: Array[int] = []

# Upgrade definitions
var upgrades: Array[Dictionary] = []

func _init():
	initialize_upgrades()

func initialize_upgrades():
	# Each upgrade MUST be purchased in order (index 0 before 1, etc.)
	upgrades = [
		# Tier 1 - Starter (Offline unlocked first!)
		{
			"id": 0,
			"name": "Offline Progress I",
			"description": "Earn gold while offline (12 hour limit)",
			"cost": 5,
			"type": "offline_limit",
			"value": 12.0  # hours
		},
		{
			"id": 1,
			"name": "Damage Boost I",
			"description": "+10% damage to all attacks",
			"cost": 8,
			"type": "damage_multiplier",
			"value": 0.10
		},
		{
			"id": 2,
			"name": "Money Generation I",
			"description": "Money generates 20% faster",
			"cost": 12,
			"type": "money_speed",
			"value": 0.20
		},
		{
			"id": 3,
			"name": "Damage Boost II",
			"description": "+15% damage to all attacks",
			"cost": 20,
			"type": "damage_multiplier",
			"value": 0.15
		},
		
		# Tier 2 - Early game
		{
			"id": 4,
			"name": "Gold Boost I",
			"description": "+25% gold from enemies",
			"cost": 30,
			"type": "gold_multiplier",
			"value": 0.25
		},
		{
			"id": 5,
			"name": "Money Generation II",
			"description": "Money generates 30% faster",
			"cost": 45,
			"type": "money_speed",
			"value": 0.30
		},
		{
			"id": 6,
			"name": "Offline Progress II",
			"description": "Offline time limit increased to 24 hours",
			"cost": 65,
			"type": "offline_limit",
			"value": 24.0  # hours
		},
		{
			"id": 7,
			"name": "Critical Strike",
			"description": "5% chance for 2x damage",
			"cost": 90,
			"type": "crit_chance",
			"value": 0.05
		},
		
		# Tier 3 - Mid game
		{
			"id": 8,
			"name": "Damage Boost III",
			"description": "+25% damage to all attacks",
			"cost": 120,
			"type": "damage_multiplier",
			"value": 0.25
		},
		{
			"id": 9,
			"name": "Auto-Gold",
			"description": "Gain 1 gold per second passively",
			"cost": 160,
			"type": "auto_gold",
			"value": 1.0
		},
		{
			"id": 10,
			"name": "Gold Boost II",
			"description": "+50% gold from enemies",
			"cost": 210,
			"type": "gold_multiplier",
			"value": 0.50
		},
		{
			"id": 11,
			"name": "Offline Progress III",
			"description": "Offline time limit increased to 7 days",
			"cost": 270,
			"type": "offline_limit",
			"value": 168.0  # hours (7 days)
		},
		
		# Tier 4 - Late game
		{
			"id": 12,
			"name": "Money Generation III",
			"description": "Money generates 50% faster",
			"cost": 350,
			"type": "money_speed",
			"value": 0.50
		},
		{
			"id": 13,
			"name": "Ability Cooldown Reduction",
			"description": "All abilities cooldown 15% faster",
			"cost": 450,
			"type": "cooldown_reduction",
			"value": 0.15
		},
		{
			"id": 14,
			"name": "Damage Boost IV",
			"description": "+40% damage to all attacks",
			"cost": 600,
			"type": "damage_multiplier",
			"value": 0.40
		},
		{
			"id": 15,
			"name": "Offline Money Generation",
			"description": "Money generates while offline",
			"cost": 800,
			"type": "offline_money",
			"value": 1.0
		},
		
		# Tier 5 - End game
		{
			"id": 16,
			"name": "Boss Timer Extension",
			"description": "+5 seconds on boss timers",
			"cost": 1050,
			"type": "boss_timer",
			"value": 5.0
		},
		{
			"id": 17,
			"name": "Auto-Gold II",
			"description": "Gain 3 gold per second passively",
			"cost": 1400,
			"type": "auto_gold",
			"value": 3.0
		},
		{
			"id": 18,
			"name": "Offline Progress IV",
			"description": "Unlimited offline time!",
			"cost": 1900,
			"type": "offline_limit",
			"value": -1.0  # unlimited
		},
		{
			"id": 19,
			"name": "Ultimate Power",
			"description": "+100% damage to all attacks",
			"cost": 2500,
			"type": "damage_multiplier",
			"value": 1.00
		}
	]

func can_purchase_upgrade(upgrade_id: int) -> bool:
	# Already purchased
	if is_upgrade_purchased(upgrade_id):
		return false
	
	# Not enough points
	var upgrade = get_upgrade_by_id(upgrade_id)
	if upgrade == null or prestige_points < upgrade.cost:
		return false
	
	# Must purchase previous upgrade first (sequential unlocking)
	if upgrade_id > 0:
		if not is_upgrade_purchased(upgrade_id - 1):
			return false
	
	return true

func purchase_upgrade(upgrade_id: int) -> bool:
	if not can_purchase_upgrade(upgrade_id):
		return false
	
	var upgrade = get_upgrade_by_id(upgrade_id)
	prestige_points -= upgrade.cost
	purchased_upgrades.append(upgrade_id)
	
	print("Purchased prestige upgrade: ", upgrade.name)
	return true

func is_upgrade_purchased(upgrade_id: int) -> bool:
	return purchased_upgrades.has(upgrade_id)

func get_upgrade_by_id(upgrade_id: int) -> Dictionary:
	if upgrade_id < 0 or upgrade_id >= upgrades.size():
		return {}
	return upgrades[upgrade_id]

func is_upgrade_locked(upgrade_id: int) -> bool:
	# Locked if previous upgrade not purchased
	if upgrade_id > 0:
		return not is_upgrade_purchased(upgrade_id - 1)
	return false

# Calculate total bonus from all purchased upgrades of a type
func get_total_bonus(bonus_type: String) -> float:
	var total = 0.0
	for upgrade_id in purchased_upgrades:
		var upgrade = get_upgrade_by_id(upgrade_id)
		if upgrade.type == bonus_type:
			total += upgrade.value
	return total

# Get damage multiplier (1.0 = no bonus, 1.5 = +50%)
func get_damage_multiplier() -> float:
	return 1.0 + get_total_bonus("damage_multiplier")

# Get gold multiplier
func get_gold_multiplier() -> float:
	return 1.0 + get_total_bonus("gold_multiplier")

# Get money generation speed multiplier (higher = faster)
func get_money_speed_multiplier() -> float:
	return 1.0 + get_total_bonus("money_speed")

# Get auto-gold generation rate
func get_auto_gold_rate() -> float:
	return get_total_bonus("auto_gold")

# Get crit chance
func get_crit_chance() -> float:
	return get_total_bonus("crit_chance")

# Get cooldown reduction
func get_cooldown_reduction() -> float:
	return get_total_bonus("cooldown_reduction")

# Get boss timer extension
func get_boss_timer_extension() -> float:
	return get_total_bonus("boss_timer")

# NEW: Offline progression methods
func has_offline_progression() -> bool:
	return is_upgrade_purchased(0)  # First offline upgrade (now ID 0!)

func get_offline_time_limit() -> float:
	# Returns hours, -1 for unlimited
	if is_upgrade_purchased(18):  # Unlimited
		return -1.0
	elif is_upgrade_purchased(11):  # 7 days
		return 168.0
	elif is_upgrade_purchased(6):  # 24 hours
		return 24.0
	elif is_upgrade_purchased(0):  # 12 hours
		return 12.0
	return 0.0

func has_offline_money_generation() -> bool:
	return is_upgrade_purchased(15)

# Award prestige points based on level
func calculate_prestige_points_from_level(level: int) -> int:
	# Formula: Square root scaling for prestige points
	# Level 10 = 3 points, Level 50 = 7 points, Level 100 = 10 points
	if level < 10:
		return 0
	
	return int(sqrt(level - 9))

func add_prestige_points(amount: int):
	prestige_points += amount
	print("Gained ", amount, " prestige points! Total: ", prestige_points)

# Serialize for saving
func get_save_data() -> Dictionary:
	return {
		"prestige_points": prestige_points,
		"purchased_upgrades": purchased_upgrades
	}

# Deserialize from save
func load_save_data(data: Dictionary):
	prestige_points = data.get("prestige_points", 0)
	
	# Debug: Print what we're trying to load
	print("PrestigeSystem.load_save_data: Raw data received = ", data)
	
	# Convert generic Array to Array[int]
	var loaded_upgrades = data.get("purchased_upgrades", [])
	print("PrestigeSystem.load_save_data: Loaded upgrades from data = ", loaded_upgrades)
	print("PrestigeSystem.load_save_data: Type of loaded_upgrades = ", typeof(loaded_upgrades))
	
	purchased_upgrades.clear()
	
	# Handle both Array and Array[int] types
	if loaded_upgrades is Array:
		for i in range(loaded_upgrades.size()):
			var upgrade_id = loaded_upgrades[i]
			print("PrestigeSystem.load_save_data: Processing upgrade_id = ", upgrade_id, ", type = ", typeof(upgrade_id))
			
			# Convert to int if needed
			if upgrade_id is int:
				purchased_upgrades.append(upgrade_id)
			elif upgrade_id is float:
				purchased_upgrades.append(int(upgrade_id))
			elif upgrade_id is String:
				purchased_upgrades.append(int(upgrade_id))
			else:
				print("WARNING: Unknown upgrade_id type: ", typeof(upgrade_id))
	
	# Debug logging
	print("PrestigeSystem: Loaded ", prestige_points, " prestige points")
	print("PrestigeSystem: Loaded ", purchased_upgrades.size(), " purchased upgrades: ", purchased_upgrades)
