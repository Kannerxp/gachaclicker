extends Control

const PrestigeSystem = preload("res://PrestigeSystem.gd")

signal upgrade_purchased(upgrade_id: int)
signal ascend_requested
signal back_pressed

@onready var upgrades_container = $ScrollContainer/UpgradesVBox
@onready var points_label = $TopPanel/PointsLabel
@onready var ascend_button = $TopPanel/AscendButton
@onready var back_button = $BackButton

var prestige_system: PrestigeSystem = null

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	ascend_button.pressed.connect(_on_ascend_pressed)

func _on_back_pressed():
	back_pressed.emit()

func _on_ascend_pressed():
	ascend_requested.emit()

func setup(system: PrestigeSystem):
	prestige_system = system
	refresh_display()

func refresh_display():
	if prestige_system == null:
		return
	
	# Update points display
	points_label.text = "Prestige Points: " + str(prestige_system.prestige_points)
	
	# Clear existing upgrade buttons
	for child in upgrades_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add title
	var title = Label.new()
	title.text = "Permanent Upgrades"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.GOLD)
	upgrades_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "(Must purchase in order)"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	upgrades_container.add_child(subtitle)
	
	var separator = HSeparator.new()
	upgrades_container.add_child(separator)
	
	# Add upgrade buttons
	for upgrade in prestige_system.upgrades:
		var upgrade_display = create_upgrade_display(upgrade)
		upgrades_container.add_child(upgrade_display)

func create_upgrade_display(upgrade: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(500, 0)
	
	# Main button container
	var hbox = HBoxContainer.new()
	container.add_child(hbox)
	
	# Status indicator
	var status_label = Label.new()
	status_label.custom_minimum_size = Vector2(80, 40)
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if prestige_system.is_upgrade_purchased(upgrade.id):
		status_label.text = "✓ OWNED"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	elif prestige_system.is_upgrade_locked(upgrade.id):
		status_label.text = "🔒 LOCKED"
		status_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		status_label.text = str(upgrade.cost) + " PP"
		status_label.add_theme_color_override("font_color", Color.GOLD)
	
	status_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(status_label)
	
	# Upgrade info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Name
	var name_label = Label.new()
	name_label.text = upgrade.name
	name_label.add_theme_font_size_override("font_size", 16)
	
	if prestige_system.is_upgrade_purchased(upgrade.id):
		name_label.add_theme_color_override("font_color", Color.GREEN)
	elif prestige_system.is_upgrade_locked(upgrade.id):
		name_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		name_label.add_theme_color_override("font_color", Color.WHITE)
	
	info_vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(desc_label)
	
	# Buy button (only if not purchased and not locked)
	if not prestige_system.is_upgrade_purchased(upgrade.id) and not prestige_system.is_upgrade_locked(upgrade.id):
		var buy_button = Button.new()
		buy_button.text = "Purchase"
		buy_button.custom_minimum_size = Vector2(100, 40)
		buy_button.disabled = not prestige_system.can_purchase_upgrade(upgrade.id)
		buy_button.pressed.connect(_on_purchase_upgrade.bind(upgrade.id))
		hbox.add_child(buy_button)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _on_purchase_upgrade(upgrade_id: int):
	if prestige_system.purchase_upgrade(upgrade_id):
		upgrade_purchased.emit(upgrade_id)
		refresh_display()

func update_ascend_button(current_level: int):
	var points_to_gain = prestige_system.calculate_prestige_points_from_level(current_level)
	
	if points_to_gain > 0:
		ascend_button.text = "Ascend (+" + str(points_to_gain) + " PP)"
		ascend_button.disabled = false
		ascend_button.tooltip_text = "Reset to level 1, gain " + str(points_to_gain) + " Prestige Points"
	else:
		ascend_button.text = "Ascend (Level 10+)"
		ascend_button.disabled = true
		ascend_button.tooltip_text = "Reach level 10 to unlock Ascension"
