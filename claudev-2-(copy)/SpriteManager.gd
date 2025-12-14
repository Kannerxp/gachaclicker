class_name SpriteManager
extends RefCounted

# ========== SPRITE PATHS ==========
# Change these paths to point to your actual sprite files
# For now, they'll fall back to colored rectangles if sprites don't exist

# UI Icons
const ICON_GOLD = "res://icons/ui/gold.png"
const ICON_GEMS = "res://icons/ui/gems.png"
const ICON_PULLS = "res://icons/ui/pulls.png"
const ICON_MONEY = "res://icons/ui/money.png"

# Enemy Sprites
const ENEMY_NORMAL = "res://sprites/enemies/enemy_normal.png"
const ENEMY_BOSS = "res://sprites/enemies/enemy_boss.png"

# Character Sprites (by ID)
const CHARACTER_SPRITES = {
	0: "res://sprites/characters/player.png",
	1: "res://sprites/characters/warrior.png",
	2: "res://sprites/characters/scout.png",
	3: "res://sprites/characters/guard.png",
	4: "res://sprites/characters/hunter.png",
	5: "res://sprites/characters/knight.png",
	6: "res://sprites/characters/archer.png",
	7: "res://sprites/characters/mage.png",
	8: "res://sprites/characters/rogue.png",
	9: "res://sprites/characters/paladin.png",
	10: "res://sprites/characters/assassin.png",
	11: "res://sprites/characters/wizard.png",
	12: "res://sprites/characters/dragonslayer.png",
	13: "res://sprites/characters/archmage.png"
}

# Weapon Sprites (by ID)
const WEAPON_SPRITES = {
	101: "res://sprites/weapons/iron_sword.png",
	102: "res://sprites/weapons/steel_dagger.png",
	103: "res://sprites/weapons/oak_staff.png",
	104: "res://sprites/weapons/silver_blade.png",
	105: "res://sprites/weapons/mystic_bow.png",
	106: "res://sprites/weapons/crystal_orb.png",
	107: "res://sprites/weapons/excalibur.png",
	108: "res://sprites/weapons/shadow_strike.png",
	109: "res://sprites/weapons/dragons_fury.png"
}

# Element icon paths (you already have these)
const ELEMENT_ICONS = {
	"fire": "res://icons/elements/fire.png",
	"ice": "res://icons/elements/ice.png",
	"lightning": "res://icons/elements/lightning.png",
	"earth": "res://icons/elements/earth.png",
	"light": "res://icons/elements/light.png",
	"dark": "res://icons/elements/dark.png",
	"neutral": "res://icons/elements/neutral.png"
}

# ========== UTILITY FUNCTIONS ==========

static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func get_icon_texture(icon_type: String) -> Texture2D:
	match icon_type:
		"gold":
			return load_texture(ICON_GOLD)
		"gems":
			return load_texture(ICON_GEMS)
		"pulls":
			return load_texture(ICON_PULLS)
		"money":
			return load_texture(ICON_MONEY)
	return null

static func get_enemy_texture(is_boss: bool) -> Texture2D:
	if is_boss:
		return load_texture(ENEMY_BOSS)
	return load_texture(ENEMY_NORMAL)

static func get_character_texture(character_id: int) -> Texture2D:
	if CHARACTER_SPRITES.has(character_id):
		return load_texture(CHARACTER_SPRITES[character_id])
	return null

static func get_weapon_texture(weapon_id: int) -> Texture2D:
	if WEAPON_SPRITES.has(weapon_id):
		return load_texture(WEAPON_SPRITES[weapon_id])
	return null

static func get_element_texture(element: Character.Element) -> Texture2D:
	var element_name = Character.Element.keys()[element].to_lower()
	if ELEMENT_ICONS.has(element_name):
		return load_texture(ELEMENT_ICONS[element_name])
	return null

# ========== SPRITE CREATION HELPERS ==========

static func create_sprite_or_fallback(texture: Texture2D, fallback_color: Color, size: Vector2) -> Control:
	if texture != null:
		# Create TextureRect for actual sprite
		var sprite = TextureRect.new()
		sprite.texture = texture
		sprite.custom_minimum_size = size
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return sprite
	else:
		# Fallback to ColorRect
		var rect = ColorRect.new()
		rect.color = fallback_color
		rect.custom_minimum_size = size
		return rect

static func create_character_sprite(character_id: int, rarity_color: Color, size: Vector2 = Vector2(60, 60)) -> Control:
	var texture = get_character_texture(character_id)
	return create_sprite_or_fallback(texture, rarity_color, size)

static func create_weapon_sprite(weapon_id: int, rarity_color: Color, size: Vector2 = Vector2(40, 40)) -> Control:
	var texture = get_weapon_texture(weapon_id)
	return create_sprite_or_fallback(texture, rarity_color, size)

static func create_enemy_sprite(is_boss: bool, size: Vector2 = Vector2(150, 130)) -> Control:
	var texture = get_enemy_texture(is_boss)
	var fallback_color = Color.RED if is_boss else Color(0.8, 0.4, 0.4)
	return create_sprite_or_fallback(texture, fallback_color, size)

static func create_icon_sprite(icon_type: String, size: Vector2 = Vector2(24, 24)) -> Control:
	var texture = get_icon_texture(icon_type)
	if texture != null:
		var sprite = TextureRect.new()
		sprite.texture = texture
		sprite.custom_minimum_size = size
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return sprite
	# If no icon, return empty control (text labels will handle it)
	return Control.new()
