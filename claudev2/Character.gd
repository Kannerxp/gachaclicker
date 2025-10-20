class_name Character
extends Resource

enum Rarity {
	COMMON,
	RARE,
	LEGENDARY,
	MYTHIC
}

enum Type {
	CHARACTER,
	WEAPON
}

@export var name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var character_type: Type = Type.CHARACTER
@export var level: int = 1
@export var base_damage: int = 10
@export var is_unlocked: bool = false
@export var duplicate_count: int = 0
@export var character_id: int = -1  # Unique identifier for duplicate checking

# Weapon system
var equipped_weapon: Character = null
var is_player_character: bool = false  # True only for the main player character

# Rarity-based stats
func get_rarity_multiplier() -> float:
	match rarity:
		Rarity.COMMON:
			return 1.0
		Rarity.RARE:
			return 1.5
		Rarity.LEGENDARY:
			return 2.5
		Rarity.MYTHIC:
			return 4.0
		_:
			return 1.0

func get_total_damage() -> int:
	var base = int(base_damage * get_rarity_multiplier())
	var level_bonus = (level - 1) * int(5 * get_rarity_multiplier())
	var total = base + level_bonus
	
	if equipped_weapon != null:
		total += equipped_weapon.get_weapon_damage()
	
	return total

func get_weapon_damage() -> int:
	if character_type != Type.WEAPON:
		return 0
	var base = int(base_damage * get_rarity_multiplier())
	return base + (level - 1) * int(3 * get_rarity_multiplier())

func upgrade_character(gold_cost: int) -> bool:
	level += 1
	return true

func get_upgrade_cost() -> int:
	var base_cost = level * 50
	return int(base_cost * get_rarity_multiplier())

func add_duplicate():
	duplicate_count += 1
	# Each duplicate gives a small permanent boost
	base_damage += int(2 * get_rarity_multiplier())

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.RARE:
			return Color.CYAN
		Rarity.LEGENDARY:
			return Color.GOLD
		Rarity.MYTHIC:
			return Color.MAGENTA
		_:
			return Color.WHITE
