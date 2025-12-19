extends Control

signal purchase_requested(item_id: String, category: String)
signal back_pressed

# Shop categories
enum Category {
	GEMS,
	BUNDLES,
	PULLS,
	MATERIALS,
	GENERAL,
	OUTFITS,
	EQUIPMENT
}

var current_category: Category = Category.GEMS
var current_gold: int = 0
var current_gems: int = 0
var current_pulls: int = 0

# Shop item data
var gems_items: Array[Dictionary] = []
var pulls_items: Array[Dictionary] = []
var gold_items: Array[Dictionary] = []

# Daily limits (would be saved/loaded from save file)
var daily_limits: Dictionary = {}

@onready var gold_icon = $TopBar/CurrencyContainer/GoldIcon
@onready var gold_label = $TopBar/CurrencyContainer/GoldLabel
@onready var gems_icon = $TopBar/CurrencyContainer/GemsIcon
@onready var gems_label = $TopBar/CurrencyContainer/GemsLabel
@onready var pulls_icon = $TopBar/CurrencyContainer/PullsIcon
@onready var pulls_label = $TopBar/CurrencyContainer/PullsLabel

@onready var category_buttons_container = $MainContent/Sidebar/SidebarContent/CategoryButtons
@onready var search_bar = $MainContent/ContentArea/SearchBar/SearchInput
@onready var item_grid = $MainContent/ContentArea/ScrollContainer/ItemGrid
@onready var back_button = $BackButton

# Category buttons
var category_buttons: Dictionary = {}

func _ready():
	# Load currency icons
	gold_icon.texture = SpriteManager.get_icon_texture("gold")
	gems_icon.texture = SpriteManager.get_icon_texture("gems")
	pulls_icon.texture = SpriteManager.get_icon_texture("pulls")
	
	# Initialize shop items
	initialize_gems_items()
	initialize_pulls_items()
	
	# Setup category buttons
	setup_category_buttons()
	
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	search_bar.text_changed.connect(_on_search_changed)
	
	# Show gems category by default
	switch_category(Category.GEMS)

func initialize_gems_items():
	gems_items = [
		{
			"id": "gems_1",
			"name": "1 Gem",
			"gems": 1,
			"price": 0.99,
			"daily_limit": 5,
			"discount": 0
		},
		{
			"id": "gems_5",
			"name": "5 Gems",
			"gems": 5,
			"price": 4.99,
			"daily_limit": 3,
			"discount": 20
		},
		{
			"id": "gems_10",
			"name": "10 Gems",
			"gems": 10,
			"price": 9.99,
			"daily_limit": 1,
			"discount": 20
		},
		{
			"id": "gems_small",
			"name": "1 Gem",
			"gems": 1,
			"price": 0.99,
			"daily_limit": -1,  # No limit
			"discount": 0
		},
		{
			"id": "gems_medium",
			"name": "5 Gems",
			"gems": 5,
			"price": 4.99,
			"daily_limit": -1,
			"discount": 0
		},
		{
			"id": "gems_large",
			"name": "X Gems",
			"gems": 20,
			"price": 19.99,
			"daily_limit": -1,
			"discount": 0
		},
		{
			"id": "gems_xlarge",
			"name": "X Gems",
			"gems": 50,
			"price": 49.99,
			"daily_limit": -1,
			"discount": 0
		},
		{
			"id": "gems_mega",
			"name": "X Gems",
			"gems": 100,
			"price": 99.99,
			"daily_limit": -1,
			"discount": 0
		}
	]

func initialize_pulls_items():
	pulls_items = [
		{
			"id": "pulls_1",
			"name": "1 Pull",
			"pulls": 1,
			"price": 5,
			"daily_limit": 5,
			"discount": 0
		},
		{
			"id": "pulls_5",
			"name": "5 Pulls",
			"pulls": 5,
			"price": 25,
			"daily_limit": 3,
			"discount": 20
		},
		{
			"id": "pulls_10",
			"name": "10 Pulls",
			"pulls": 50,
			"price": 999,
			"daily_limit": 1,
			"discount": 20
		},
		{
			"id": "pulls_small",
			"name": "1 Pull",
			"pulls": 1,
			"price": 5,
			"daily_limit": -1,
			"discount": 0
		},
		{
			"id": "pulls_medium",
			"name": "5 Pulls",
			"pulls": 5,
			"price": 25,
			"daily_limit": -1,
			"discount": 0
		},
		{
			"id": "pulls_large",
			"name": "X Pulls",
			"pulls": 20,
			"price": 100,
			"daily_limit": -1,
			"discount": 0
		}
	]

func setup_category_buttons():
	var categories = [
		{"name": "Gems", "category": Category.GEMS},
		{"name": "Bundles", "category": Category.BUNDLES},
		{"name": "Pulls", "category": Category.PULLS},
		{"name": "Materials", "category": Category.MATERIALS},
		{"name": "General", "category": Category.GENERAL},
		{"name": "Outfits", "category": Category.OUTFITS},
		{"name": "Equipment", "category": Category.EQUIPMENT}
	]
	
	for cat_data in categories:
		var button = Button.new()
		button.text = cat_data.name
		button.custom_minimum_size = Vector2(180, 50)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_on_category_button_pressed.bind(cat_data.category))
		
		category_buttons_container.add_child(button)
		category_buttons[cat_data.category] = button

func _on_category_button_pressed(category: Category):
	switch_category(category)

func switch_category(category: Category):
	current_category = category
	
	# Update button states
	for cat in category_buttons:
		var button = category_buttons[cat]
		if cat == category:
			button.modulate = Color(0.7, 0.9, 1.0)  # Highlighted
			button.disabled = true
		else:
			button.modulate = Color.WHITE
			button.disabled = false
	
	# Refresh items
	refresh_items()

func refresh_items():
	# Clear existing items
	for child in item_grid.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Get items for current category
	var items: Array[Dictionary] = []
	match current_category:
		Category.GEMS:
			items = gems_items
		Category.PULLS:
			items = pulls_items
		Category.BUNDLES, Category.MATERIALS, Category.GENERAL, Category.OUTFITS, Category.EQUIPMENT:
			# Coming soon message
			show_coming_soon_message()
			return
	
	# Create item cards
	for item in items:
		var card = create_item_card(item)
		item_grid.add_child(card)

func show_coming_soon_message():
	var message = Label.new()
	message.text = "Coming Soon"
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color.GRAY)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.custom_minimum_size = Vector2(600, 400)
	item_grid.add_child(message)

func create_item_card(item: Dictionary) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(200, 240)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	card.add_child(vbox)
	
	# Discount badge (if applicable)
	if item.discount > 0:
		var discount_badge = create_discount_badge(item.discount)
		discount_badge.position = Vector2(5, 5)
		card.add_child(discount_badge)
	
	# Item name/amount
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Icon (gems or pulls)
	var icon = TextureRect.new()
	if item.has("gems"):
		icon.texture = SpriteManager.get_icon_texture("gems")
	elif item.has("pulls"):
		icon.texture = SpriteManager.get_icon_texture("pulls")
	
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)
	
	# Daily limit info
	var limit_label = Label.new()
	if item.daily_limit > 0:
		var remaining = get_daily_limit_remaining(item.id, item.daily_limit)
		limit_label.text = "Left today: " + str(remaining)
	else:
		limit_label.text = "No limit"
	limit_label.add_theme_font_size_override("font_size", 12)
	limit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(limit_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Price / Buy button
	var button_container = MarginContainer.new()
	button_container.add_theme_constant_override("margin_top", 10)
	vbox.add_child(button_container)
	
	var remaining = get_daily_limit_remaining(item.id, item.daily_limit)
	var is_sold_out = item.daily_limit > 0 and remaining <= 0
	
	if is_sold_out:
		var sold_out_label = Label.new()
		sold_out_label.text = "Sold Out"
		sold_out_label.add_theme_font_size_override("font_size", 16)
		sold_out_label.add_theme_color_override("font_color", Color.RED)
		sold_out_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_container.add_child(sold_out_label)
	else:
		var buy_button = Button.new()
		buy_button.text = format_price(item.price)
		buy_button.custom_minimum_size = Vector2(0, 40)
		buy_button.add_theme_font_size_override("font_size", 16)
		buy_button.pressed.connect(_on_purchase_button_pressed.bind(item))
		button_container.add_child(buy_button)
	
	return card

func create_discount_badge(discount: int) -> Control:
	var badge = Panel.new()
	badge.custom_minimum_size = Vector2(60, 60)
	
	# Make it circular (using a styled panel)
	var style = StyleBoxFlat.new()
	style.bg_color = Color.RED
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	badge.add_theme_stylebox_override("panel", style)
	
	# Discount text
	var label = Label.new()
	label.text = "-" + str(discount) + "%"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	badge.add_child(label)
	
	return badge

func format_price(amount: float) -> String:
	return "$%.2f" % amount

func get_daily_limit_remaining(item_id: String, max_limit: int) -> int:
	if max_limit < 0:
		return 999  # No limit
	
	var purchased_today = daily_limits.get(item_id, 0)
	return max(0, max_limit - purchased_today)

func _on_purchase_button_pressed(item: Dictionary):
	# Check if can purchase
	var remaining = get_daily_limit_remaining(item.id, item.daily_limit)
	if item.daily_limit > 0 and remaining <= 0:
		show_message("Daily limit reached!")
		return
	
	# Emit purchase signal
	var category_name = Category.keys()[current_category]
	purchase_requested.emit(item.id, category_name)
	
	# Update daily limit
	if item.daily_limit > 0:
		daily_limits[item.id] = daily_limits.get(item.id, 0) + 1
	
	# Refresh display
	refresh_items()

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func update_currency_display(gold: int, gems: int, pulls: int):
	current_gold = gold
	current_gems = gems
	current_pulls = pulls
	
	gold_label.text = "Gold: " + str(gold)
	gems_label.text = "Gems: " + str(gems)
	pulls_label.text = "Pulls: " + str(pulls)

func _on_search_changed(new_text: String):
	# TODO: Implement search filtering
	pass

func _on_back_pressed():
	back_pressed.emit()

func reset_daily_limits():
	daily_limits.clear()
	refresh_items()

func get_save_data() -> Dictionary:
	return {
		"daily_limits": daily_limits
	}

func load_save_data(data: Dictionary):
	daily_limits = data.get("daily_limits", {})
	refresh_items()
