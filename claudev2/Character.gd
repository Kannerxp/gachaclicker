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

enum Role {
	DPS,      # High damage output
	TANK,     # High health, takes damage
	SUPPORT   # Buffs team
}

enum Element {
	FIRE,
	ICE,
	LIGHTNING,
	EARTH,
	LIGHT,
	DARK,
	NEUTRAL
}

enum Formation {
	FRONT,    # Front row - takes more damage but deals more
	BACK      # Back row - takes less damage but deals less
}

@export var name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var character_type: Type = Type.CHARACTER
@export var level: int = 1
@export var base_damage: int = 10
@export var is_unlocked: bool = false
@export var duplicate_count: int = 0
@export var character_id: int = -1  # Unique identifier for duplicate checking

# New attributes for team composition
@export var role: Role = Role.DPS
@export var element: Element = Element.NEUTRAL
@export var formation_position: Formation = Formation.FRONT

# Weapon system
var equipped_weapon: Character = null
var is_player_character: bool = false  # True only for the main player character
var is_in_team: bool = false  # Whether this character is in the active team

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

func get_role_name() -> String:
	match role:
		Role.DPS:
			return "DPS"
		Role.TANK:
			return "Tank"
		Role.SUPPORT:
			return "Support"
		_:
			return "Unknown"

func get_element_name() -> String:
	match element:
		Element.FIRE:
			return "Fire"
		Element.ICE:
			return "Ice"
		Element.LIGHTNING:
			return "Lightning"
		Element.EARTH:
			return "Earth"
		Element.LIGHT:
			return "Light"
		Element.DARK:
			return "Dark"
		Element.NEUTRAL:
			return "Neutral"
		_:
			return "Unknown"

func get_element_icon() -> String:
	match element:
		Element.FIRE:
			return "🔥"
		Element.ICE:
			return "❄️"
		Element.LIGHTNING:
			return "⚡"
		Element.EARTH:
			return "🌍"
		Element.LIGHT:
			return "✨"
		Element.DARK:
			return "🌙"
		Element.NEUTRAL:
			return "⭕"
		_:
			return ""

func get_role_multiplier() -> float:
	match role:
		Role.DPS:
			return 1.2  # 20% more damage
		Role.TANK:
			return 0.8  # 20% less damage but tankier
		Role.SUPPORT:
			return 0.9  # 10% less damage but provides buffs
		_:
			return 1.0

func get_formation_multiplier() -> float:
	match formation_position:
		Formation.FRONT:
			return 1.1  # 10% more damage in front
		Formation.BACK:
			return 0.95 # 5% less damage in back (safer)
		_:
			return 1.0
