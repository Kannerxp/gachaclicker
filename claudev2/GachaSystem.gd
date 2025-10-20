class_name GachaSystem
extends RefCounted

# Pity system
var character_pity_count: int = 0
var weapon_pity_count: int = 0
var character_pity_limit: int = 90  # Guaranteed legendary at 90 pulls
var weapon_pity_limit: int = 80    # Guaranteed legendary weapon at 80 pulls

# Character pools
var character_pool: Array[Dictionary] = []
var weapon_pool: Array[Dictionary] = []

# Gacha rates (base rates)
var character_rates = {
	Character.Rarity.COMMON: 0.60,    # 60%
	Character.Rarity.RARE: 0.30,      # 30%
	Character.Rarity.LEGENDARY: 0.095, # 9.5%
	Character.Rarity.MYTHIC: 0.005     # 0.5%
}

var weapon_rates = {
	Character.Rarity.COMMON: 0.70,    # 70%
	Character.Rarity.RARE: 0.25,      # 25%
	Character.Rarity.LEGENDARY: 0.045, # 4.5%
	Character.Rarity.MYTHIC: 0.005     # 0.5%
}

func _init():
	initialize_character_pool()
	initialize_weapon_pool()

func initialize_character_pool():
	# Common Characters
	character_pool.append({"id": 1, "name": "Warrior", "rarity": Character.Rarity.COMMON, "damage": 15})
	character_pool.append({"id": 2, "name": "Scout", "rarity": Character.Rarity.COMMON, "damage": 12})
	character_pool.append({"id": 3, "name": "Guard", "rarity": Character.Rarity.COMMON, "damage": 18})
	character_pool.append({"id": 4, "name": "Hunter", "rarity": Character.Rarity.COMMON, "damage": 14})
	
	# Rare Characters
	character_pool.append({"id": 5, "name": "Knight", "rarity": Character.Rarity.RARE, "damage": 25})
	character_pool.append({"id": 6, "name": "Archer", "rarity": Character.Rarity.RARE, "damage": 22})
	character_pool.append({"id": 7, "name": "Mage", "rarity": Character.Rarity.RARE, "damage": 28})
	character_pool.append({"id": 8, "name": "Rogue", "rarity": Character.Rarity.RARE, "damage": 24})
	
	# Legendary Characters
	character_pool.append({"id": 9, "name": "Paladin", "rarity": Character.Rarity.LEGENDARY, "damage": 45})
	character_pool.append({"id": 10, "name": "Assassin", "rarity": Character.Rarity.LEGENDARY, "damage": 50})
	character_pool.append({"id": 11, "name": "Wizard", "rarity": Character.Rarity.LEGENDARY, "damage": 48})
	
	# Mythic Characters
	character_pool.append({"id": 12, "name": "Dragon Slayer", "rarity": Character.Rarity.MYTHIC, "damage": 80})
	character_pool.append({"id": 13, "name": "Archmage", "rarity": Character.Rarity.MYTHIC, "damage": 85})

func initialize_weapon_pool():
	# Common Weapons
	weapon_pool.append({"id": 101, "name": "Iron Sword", "rarity": Character.Rarity.COMMON, "damage": 8})
	weapon_pool.append({"id": 102, "name": "Steel Dagger", "rarity": Character.Rarity.COMMON, "damage": 6})
	weapon_pool.append({"id": 103, "name": "Oak Staff", "rarity": Character.Rarity.COMMON, "damage": 7})
	
	# Rare Weapons
	weapon_pool.append({"id": 104, "name": "Silver Blade", "rarity": Character.Rarity.RARE, "damage": 15})
	weapon_pool.append({"id": 105, "name": "Mystic Bow", "rarity": Character.Rarity.RARE, "damage": 18})
	weapon_pool.append({"id": 106, "name": "Crystal Orb", "rarity": Character.Rarity.RARE, "damage": 16})
	
	# Legendary Weapons
	weapon_pool.append({"id": 107, "name": "Excalibur", "rarity": Character.Rarity.LEGENDARY, "damage": 35})
	weapon_pool.append({"id": 108, "name": "Shadow Strike", "rarity": Character.Rarity.LEGENDARY, "damage": 40})
	
	# Mythic Weapons
	weapon_pool.append({"id": 109, "name": "Dragon's Fury", "rarity": Character.Rarity.MYTHIC, "damage": 70})

func perform_character_pull() -> Character:
	character_pity_count += 1
	var target_rarity = determine_character_rarity()
	var character_data = get_random_character_by_rarity(target_rarity)
	
	# Reset pity if we got legendary or higher
	if target_rarity >= Character.Rarity.LEGENDARY:
		character_pity_count = 0
	
	return create_character_from_data(character_data)

func perform_character_multi_pull(count: int = 10) -> Array[Character]:
	var results: Array[Character] = []
	
	for i in count:
		results.append(perform_character_pull())
	
	return results

func perform_weapon_pull() -> Character:
	weapon_pity_count += 1
	var target_rarity = determine_weapon_rarity()
	var weapon_data = get_random_weapon_by_rarity(target_rarity)
	
	# Reset pity if we got legendary or higher
	if target_rarity >= Character.Rarity.LEGENDARY:
		weapon_pity_count = 0
	
	return create_weapon_from_data(weapon_data)

func perform_weapon_multi_pull(count: int = 10) -> Array[Character]:
	var results: Array[Character] = []
	
	for i in count:
		results.append(perform_weapon_pull())
	
	return results

func determine_character_rarity() -> Character.Rarity:
	# Check pity system
	if character_pity_count >= character_pity_limit:
		return Character.Rarity.LEGENDARY
	
	# Increase rates as pity builds up
	var pity_bonus = float(character_pity_count) / float(character_pity_limit) * 0.05
	
	var roll = randf()
	var cumulative = 0.0
	
	# Check from highest rarity to lowest
	for rarity in [Character.Rarity.MYTHIC, Character.Rarity.LEGENDARY, Character.Rarity.RARE, Character.Rarity.COMMON]:
		var rate = character_rates[rarity]
		if rarity >= Character.Rarity.LEGENDARY:
			rate += pity_bonus
		
		cumulative += rate
		if roll <= cumulative:
			return rarity
	
	return Character.Rarity.COMMON

func determine_weapon_rarity() -> Character.Rarity:
	# Check pity system
	if weapon_pity_count >= weapon_pity_limit:
		return Character.Rarity.LEGENDARY
	
	# Increase rates as pity builds up
	var pity_bonus = float(weapon_pity_count) / float(weapon_pity_limit) * 0.03
	
	var roll = randf()
	var cumulative = 0.0
	
	# Check from highest rarity to lowest
	for rarity in [Character.Rarity.MYTHIC, Character.Rarity.LEGENDARY, Character.Rarity.RARE, Character.Rarity.COMMON]:
		var rate = weapon_rates[rarity]
		if rarity >= Character.Rarity.LEGENDARY:
			rate += pity_bonus
		
		cumulative += rate
		if roll <= cumulative:
			return rarity
	
	return Character.Rarity.COMMON

func get_random_character_by_rarity(rarity: Character.Rarity) -> Dictionary:
	var filtered_pool = character_pool.filter(func(char): return char.rarity == rarity)
	if filtered_pool.is_empty():
		return character_pool[0]  # Fallback
	return filtered_pool[randi() % filtered_pool.size()]

func get_random_weapon_by_rarity(rarity: Character.Rarity) -> Dictionary:
	var filtered_pool = weapon_pool.filter(func(weapon): return weapon.rarity == rarity)
	if filtered_pool.is_empty():
		return weapon_pool[0]  # Fallback
	return filtered_pool[randi() % filtered_pool.size()]

func create_character_from_data(data: Dictionary) -> Character:
	var character = Character.new()
	character.character_id = data.id
	character.name = data.name
	character.rarity = data.rarity
	character.character_type = Character.Type.CHARACTER
	character.base_damage = data.damage
	character.level = 1
	character.is_unlocked = true
	character.duplicate_count = 0
	return character

func create_weapon_from_data(data: Dictionary) -> Character:
	var weapon = Character.new()
	weapon.character_id = data.id
	weapon.name = data.name
	weapon.rarity = data.rarity
	weapon.character_type = Character.Type.WEAPON
	weapon.base_damage = data.damage
	weapon.level = 1
	weapon.is_unlocked = true
	weapon.duplicate_count = 0
	return weapon

func get_pity_info() -> Dictionary:
	return {
		"character_pity": character_pity_count,
		"character_pity_limit": character_pity_limit,
		"weapon_pity": weapon_pity_count,
		"weapon_pity_limit": weapon_pity_limit
	}
