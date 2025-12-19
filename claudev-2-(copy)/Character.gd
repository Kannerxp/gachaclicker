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
	FRONT,    # Front row - more damage, slower abilities
	BACK      # Back row - less damage, faster abilities
}

# Material types for upgrades
enum MaterialType {
	BASIC,      # Levels 21-40
	ADVANCED,   # Levels 41-60
	EXPERT,     # Levels 61-80
	MASTER      # Levels 81-100
}

@export var name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var character_type: Type = Type.CHARACTER
@export var level: int = 1
@export var base_damage: int = 10
@export var is_unlocked: bool = false
@export var duplicate_count: int = 0
@export var character_id: int = -1

@export var role: Role = Role.DPS
@export var element: Element = Element.NEUTRAL
@export var formation_position: Formation = Formation.FRONT

var equipped_weapon: Character = null
var is_player_character: bool = false
var is_in_team: bool = false

var ability_cooldown: float = 0.0
var ability_cooldown_max: float = 10.0

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

# NEW: Get material requirements for upgrade
func get_material_requirement() -> Dictionary:
	var next_level = level + 1
	
	# No materials needed for levels 1-20
	if next_level <= 20:
		return {}
	
	# Determine which material and how much
	var material_type: MaterialType
	var amount: int
	
	if next_level <= 40:
		material_type = MaterialType.BASIC
		amount = int(1 * get_rarity_multiplier())
	elif next_level <= 60:
		material_type = MaterialType.ADVANCED
		amount = int(2 * get_rarity_multiplier())
	elif next_level <= 80:
		material_type = MaterialType.EXPERT
		amount = int(3 * get_rarity_multiplier())
	else:  # 81-100
		material_type = MaterialType.MASTER
		amount = int(5 * get_rarity_multiplier())
	
	return {
		"type": material_type,
		"amount": amount
	}

# NEW: Get material name as string
static func get_material_name(mat_type: MaterialType) -> String:
	match mat_type:
		MaterialType.BASIC:
			return "Basic Essence"
		MaterialType.ADVANCED:
			return "Advanced Essence"
		MaterialType.EXPERT:
			return "Expert Essence"
		MaterialType.MASTER:
			return "Master Essence"
		_:
			return "Unknown"

func add_duplicate():
	duplicate_count += 1
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
			return ""

func get_element_icon_texture() -> Texture2D:
	match element:
		Element.FIRE:
			return load("res://icons/elements/fire.png")
		Element.ICE:
			return load("res://icons/elements/ice.png")
		Element.LIGHTNING:
			return load("res://icons/elements/lightning.png")
		Element.EARTH:
			return load("res://icons/elements/earth.png")
		Element.LIGHT:
			return load("res://icons/elements/light.png")
		Element.DARK:
			return load("res://icons/elements/dark.png")
		Element.NEUTRAL:
			return load("res://icons/elements/neutral.png")
		_:
			return null

func get_role_multiplier() -> float:
	match role:
		Role.DPS:
			return 1.2
		Role.TANK:
			return 0.8
		Role.SUPPORT:
			return 0.9
		_:
			return 1.0

func get_formation_multiplier() -> float:
	match formation_position:
		Formation.FRONT:
			return 1.15
		Formation.BACK:
			return 0.90
		_:
			return 1.0

func get_formation_cooldown_multiplier() -> float:
	match formation_position:
		Formation.FRONT:
			return 1.20
		Formation.BACK:
			return 0.75
		_:
			return 1.0

func get_modified_ability_cooldown() -> float:
	var base_cooldown = ability_cooldown_max * get_formation_cooldown_multiplier()
	return base_cooldown

func is_ability_ready() -> bool:
	return ability_cooldown <= 0.0

func get_ability_cooldown_percent() -> float:
	var modified_max = get_modified_ability_cooldown()
	if modified_max <= 0:
		return 1.0
	return 1.0 - (ability_cooldown / modified_max)

func start_ability_cooldown():
	ability_cooldown = get_modified_ability_cooldown()

func update_ability_cooldown(delta: float):
	if ability_cooldown > 0:
		ability_cooldown = max(0, ability_cooldown - delta)

func get_ability_name() -> String:
	match role:
		Role.DPS:
			return "Strike"
		Role.TANK:
			return "Weaken"
		Role.SUPPORT:
			return "Empower"
		_:
			return "Ability"

func get_ability_damage() -> int:
	if role == Role.DPS:
		return get_total_damage() * 5
	return 0

func get_formation_display_text() -> String:
	match formation_position:
		Formation.FRONT:
			return "FRONT (+15% DMG, +20% Cooldown)"
		Formation.BACK:
			return "BACK (-10% DMG, -25% Cooldown)"
		_:
			return "UNKNOWN"
